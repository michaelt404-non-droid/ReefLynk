import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { timingSafeEqual } from "https://deno.land/std@0.177.0/crypto/timing_safe_equal.ts";

// Sensor readings posted by the reef controller ESP32.
//
// Request:  POST, header X-Device-Key: <DEVICE_KEY>
//           body {"readings": {"temperature": 77.4, "ph": 8.12}}
// Response: 201 {"inserted": n}
//
// The ESP32 has no user session, so it authenticates with a shared device key
// instead of a JWT (deploy with --no-verify-jwt). Readings are stored under
// DEVICE_USER_ID so they show up in that user's charts like manual entries.

// Accepted sensor types and the range a real reading can fall in. Anything
// outside is a disconnected or faulty probe, not tank data.
const LIMITS: Record<string, [number, number]> = {
  temperature: [50, 104], // °F, same unit as manual entries
  ph: [0, 14],
  orp: [-500, 1000], // mV
};

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const deviceKey = Deno.env.get("DEVICE_KEY");
  const userId = Deno.env.get("DEVICE_USER_ID");
  if (!deviceKey || !userId) {
    console.error("DEVICE_KEY or DEVICE_USER_ID is not set");
    return json({ error: "Not configured" }, 500);
  }

  const encoder = new TextEncoder();
  const expectedBytes = encoder.encode(deviceKey);
  const providedBytes = encoder.encode(req.headers.get("X-Device-Key") ?? "");
  if (
    expectedBytes.length !== providedBytes.length ||
    !timingSafeEqual(expectedBytes, providedBytes)
  ) {
    return json({ error: "Unauthorized" }, 401);
  }

  let body: { readings?: unknown };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  const readings = body?.readings;
  if (!readings || typeof readings !== "object" || Array.isArray(readings)) {
    return json({ error: "Expected {\"readings\": {sensor: value}}" }, 400);
  }

  const now = new Date().toISOString();
  const rows = [];
  for (const [sensorType, value] of Object.entries(readings)) {
    const limits = LIMITS[sensorType];
    if (!limits) {
      return json({ error: `Unknown sensor type: ${sensorType}` }, 400);
    }
    if (
      typeof value !== "number" || !Number.isFinite(value) ||
      value < limits[0] || value > limits[1]
    ) {
      return json({ error: `Out of range ${sensorType}: ${value}` }, 400);
    }
    rows.push({ user_id: userId, created_at: now, sensor_type: sensorType, value });
  }
  if (rows.length === 0) {
    return json({ error: "No readings" }, 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { error } = await supabase.from("sensor_readings").insert(rows);
  if (error) {
    console.error("Insert failed:", error);
    return json({ error: "Insert failed" }, 500);
  }

  return json({ inserted: rows.length }, 201);
});
