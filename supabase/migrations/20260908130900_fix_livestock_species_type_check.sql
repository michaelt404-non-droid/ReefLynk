-- Fix livestock_species_type_check to match the species types offered in the
-- Flutter app (lib/models/livestock.dart: Livestock.speciesTypes). The
-- constraint had fallen out of sync and was rejecting "Cleanup Crew".
alter table public.livestock drop constraint if exists livestock_species_type_check;

alter table public.livestock add constraint livestock_species_type_check
  check (species_type in ('Fish', 'Coral', 'Invertebrate', 'Cleanup Crew'));
