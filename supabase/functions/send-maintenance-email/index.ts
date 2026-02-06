import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface MaintenanceTask {
  id: number;
  user_id: string;
  name: string;
  frequency_value: number;
  frequency_unit: string;
}

interface NotificationPref {
  user_id: string;
  email_address: string;
}

interface Completion {
  task_id: number;
  completed_at: string;
}

interface NotificationLog {
  task_id: number;
  sent_at: string;
}

serve(async (req: Request) => {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    const fromEmail = Deno.env.get("FROM_EMAIL") || "notifications@reeflynk.com";

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get users who have email notifications enabled
    const { data: prefs, error: prefsError } = await supabase
      .from("user_notification_preferences")
      .select("user_id, email_address")
      .eq("email_enabled", true);

    if (prefsError) throw prefsError;
    if (!prefs || prefs.length === 0) {
      return new Response(JSON.stringify({ message: "No users with email enabled" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    const userIds = (prefs as NotificationPref[]).map((p) => p.user_id);
    const emailByUser = Object.fromEntries(
      (prefs as NotificationPref[]).map((p) => [p.user_id, p.email_address])
    );

    // Get active maintenance tasks for these users
    const { data: tasks, error: tasksError } = await supabase
      .from("maintenance_tasks")
      .select("id, user_id, name, frequency_value, frequency_unit")
      .in("user_id", userIds)
      .eq("is_active", true);

    if (tasksError) throw tasksError;
    if (!tasks || tasks.length === 0) {
      return new Response(JSON.stringify({ message: "No active tasks" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Get latest completions for these tasks
    const taskIds = (tasks as MaintenanceTask[]).map((t) => t.id);
    const { data: completions } = await supabase
      .from("maintenance_completions")
      .select("task_id, completed_at")
      .in("task_id", taskIds)
      .order("completed_at", { ascending: false });

    const latestCompletion: Record<number, string> = {};
    for (const c of (completions ?? []) as Completion[]) {
      if (!latestCompletion[c.task_id]) {
        latestCompletion[c.task_id] = c.completed_at;
      }
    }

    // Get recent notification logs to prevent duplicates (last 2 hours)
    const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString();
    const { data: recentLogs } = await supabase
      .from("notification_log")
      .select("task_id, sent_at")
      .in("task_id", taskIds)
      .eq("channel", "email")
      .gte("sent_at", twoHoursAgo);

    const recentlySent = new Set(
      ((recentLogs ?? []) as NotificationLog[]).map((l) => l.task_id)
    );

    // Determine which tasks are due within the next hour
    const now = Date.now();
    const oneHourMs = 60 * 60 * 1000;
    const dueTasks: Array<MaintenanceTask & { email: string }> = [];

    for (const task of tasks as MaintenanceTask[]) {
      if (recentlySent.has(task.id)) continue;

      const lastDone = latestCompletion[task.id];
      let dueAt: number;

      if (!lastDone) {
        // Never completed — due now
        dueAt = 0;
      } else {
        const freqMs = toMs(task.frequency_value, task.frequency_unit);
        dueAt = new Date(lastDone).getTime() + freqMs;
      }

      if (dueAt <= now + oneHourMs) {
        const email = emailByUser[task.user_id];
        if (email) {
          dueTasks.push({ ...task, email });
        }
      }
    }

    if (dueTasks.length === 0) {
      return new Response(JSON.stringify({ message: "No tasks due" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Group due tasks by user email
    const tasksByEmail: Record<string, Array<{ id: number; name: string; user_id: string }>> = {};
    for (const task of dueTasks) {
      if (!tasksByEmail[task.email]) tasksByEmail[task.email] = [];
      tasksByEmail[task.email].push({ id: task.id, name: task.name, user_id: task.user_id });
    }

    let sentCount = 0;

    for (const [email, userTasks] of Object.entries(tasksByEmail)) {
      const taskList = userTasks.map((t) => `- ${t.name}`).join("\n");
      const subject =
        userTasks.length === 1
          ? `ReefLynk Reminder: ${userTasks[0].name}`
          : `ReefLynk: ${userTasks.length} maintenance tasks due`;

      const body = `Hi there,\n\nThe following maintenance tasks are due:\n\n${taskList}\n\nOpen ReefLynk to mark them complete.\n\n— ReefLynk`;

      if (resendApiKey) {
        const res = await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: {
            Authorization: `Bearer ${resendApiKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            from: fromEmail,
            to: email,
            subject,
            text: body,
          }),
        });

        if (!res.ok) {
          console.error(`Failed to send to ${email}:`, await res.text());
          continue;
        }
      } else {
        console.log(`[DRY RUN] Would send to ${email}:\nSubject: ${subject}\n${body}`);
      }

      // Log sent notifications
      const logEntries = userTasks.map((t) => ({
        user_id: t.user_id,
        task_id: t.id,
        channel: "email",
      }));
      await supabase.from("notification_log").insert(logEntries);
      sentCount += userTasks.length;
    }

    return new Response(
      JSON.stringify({ message: `Sent ${sentCount} email notification(s)` }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Edge function error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

function toMs(value: number, unit: string): number {
  switch (unit) {
    case "hours":
      return value * 60 * 60 * 1000;
    case "days":
      return value * 24 * 60 * 60 * 1000;
    case "weeks":
      return value * 7 * 24 * 60 * 60 * 1000;
    case "months":
      return value * 30 * 24 * 60 * 60 * 1000;
    default:
      return value * 24 * 60 * 60 * 1000;
  }
}
