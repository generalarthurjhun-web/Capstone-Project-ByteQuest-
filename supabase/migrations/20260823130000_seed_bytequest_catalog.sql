-- Restore the stable ByteQuest catalog identities required by the versioned
-- assessment publishers and the Flutter learner catalog.
--
-- Scope is intentionally limited to four competencies, four COC modules, and
-- twenty missions. Activity/rubric versions, assignments, attempts, results,
-- and practice evidence are published or created through their own workflows.
-- Legacy mission lock flags remain enabled because learner access comes from
-- assignments/projections. Passing scores stay at zero so they cannot compete
-- with authoritative versioned evaluation; existing project-approved
-- gamification values are preserved during upgrades.

begin;

create temporary table bytequest_catalog_competencies (
  competency_code text primary key,
  name text not null,
  order_index integer not null
) on commit drop;

insert into pg_temp.bytequest_catalog_competencies (
  competency_code,
  name,
  order_index
)
values
  ('ELC724331', 'Install and Configure Computer Systems', 1),
  ('ELC724332', 'Set-up Computer Networks', 2),
  ('ELC724333', 'Set-up Computer Servers', 3),
  ('ELC724334', 'Maintain and Repair Computer Systems and Networks', 4);

insert into public.competencies (
  competency_code,
  name,
  order_index
)
select
  competency_code,
  name,
  order_index
from pg_temp.bytequest_catalog_competencies
on conflict do nothing;

create temporary table bytequest_catalog_modules (
  coc_code text primary key,
  competency_code text not null,
  title text not null,
  module_name text not null,
  competency_area text not null,
  total_missions integer not null,
  order_index integer not null,
  status text not null,
  difficulty public.difficulty_level not null,
  xp_reward integer not null
) on commit drop;

insert into pg_temp.bytequest_catalog_modules (
  coc_code,
  competency_code,
  title,
  module_name,
  competency_area,
  total_missions,
  order_index,
  status,
  difficulty,
  xp_reward
)
values
  (
    'coc1',
    'ELC724331',
    'Install and Configure Computer Systems',
    'Install and Configure Computer Systems',
    'Install and Configure Computer Systems',
    5,
    1,
    'published',
    'beginner',
    0
  ),
  (
    'coc2',
    'ELC724332',
    'Set-up Computer Networks',
    'Set-up Computer Networks',
    'Set-up Computer Networks',
    5,
    2,
    'published',
    'beginner',
    0
  ),
  (
    'coc3',
    'ELC724333',
    'Set-up Computer Servers',
    'Set-up Computer Servers',
    'Set-up Computer Servers',
    5,
    3,
    'published',
    'beginner',
    0
  ),
  (
    'coc4',
    'ELC724334',
    'Maintain and Repair Computer Systems and Networks',
    'Maintain and Repair Computer Systems and Networks',
    'Maintain and Repair Computer Systems and Networks',
    5,
    4,
    'published',
    'beginner',
    0
  );

insert into public.coc_modules (
  coc_code,
  title,
  module_name,
  competency_area,
  competency_id,
  total_missions,
  order_index,
  status,
  difficulty,
  xp_reward
)
select
  seed.coc_code,
  seed.title,
  seed.module_name,
  seed.competency_area,
  competency.id,
  seed.total_missions,
  seed.order_index,
  seed.status::public.mission_status,
  seed.difficulty,
  seed.xp_reward
from pg_temp.bytequest_catalog_modules seed
join public.competencies competency
  on competency.competency_code = seed.competency_code
on conflict do nothing;

create temporary table bytequest_catalog_missions (
  mission_code text primary key,
  coc_code text not null,
  competency_code text not null,
  mission_number integer not null,
  title text not null,
  description text not null,
  mission_type text not null,
  difficulty public.difficulty_level not null,
  xp_reward integer not null,
  points_reward integer not null,
  passing_score integer not null,
  estimated_time_minutes integer not null,
  status text not null,
  is_locked boolean not null,
  order_index integer not null,
  hint_count integer not null
) on commit drop;

insert into pg_temp.bytequest_catalog_missions (
  mission_code,
  coc_code,
  competency_code,
  mission_number,
  title,
  description,
  mission_type,
  difficulty,
  xp_reward,
  points_reward,
  passing_score,
  estimated_time_minutes,
  status,
  is_locked,
  order_index,
  hint_count
)
values
  (
    'coc1_m1',
    'coc1',
    'ELC724331',
    1,
    'Identify Computer Parts and Tools',
    'Learn to identify essential computer components, peripherals, and tools used in computer assembly and maintenance.',
    'identification',
    'beginner',
    0,
    0,
    0,
    10,
    'published',
    true,
    1,
    0
  ),
  (
    'coc1_m2',
    'coc1',
    'ELC724331',
    2,
    'Install Internal Components',
    'Practice installing motherboard, CPU, RAM, storage devices, and cooling systems into the computer case.',
    'drag_and_drop',
    'intermediate',
    0,
    0,
    0,
    20,
    'published',
    true,
    2,
    0
  ),
  (
    'coc1_m3',
    'coc1',
    'ELC724331',
    3,
    'Connect Power and Data Cables',
    'Learn proper cable management and connect power and data cables to motherboard and components.',
    'drag_and_drop',
    'intermediate',
    0,
    0,
    0,
    15,
    'published',
    true,
    3,
    0
  ),
  (
    'coc1_m4',
    'coc1',
    'ELC724331',
    4,
    'Configure BIOS/UEFI and Install OS',
    'Access BIOS/UEFI settings, configure boot priority, and follow OS installation procedures.',
    'configuration_form',
    'advanced',
    0,
    0,
    0,
    25,
    'published',
    true,
    4,
    0
  ),
  (
    'coc1_m5',
    'coc1',
    'ELC724331',
    5,
    'Install Drivers and Test the System',
    'Install necessary drivers and perform system tests to ensure all components work correctly.',
    'step_procedure',
    'intermediate',
    0,
    0,
    0,
    20,
    'published',
    true,
    5,
    0
  ),
  (
    'coc2_m1',
    'coc2',
    'ELC724332',
    1,
    'Identify Network Devices and Tools',
    'Recognize routers, switches, modems, cables, connectors, and network tools.',
    'identification',
    'beginner',
    0,
    0,
    0,
    10,
    'published',
    true,
    1,
    0
  ),
  (
    'coc2_m2',
    'coc2',
    'ELC724332',
    2,
    'Create Network Cables',
    'Arrange Ethernet cable wires in correct sequence following T568B standard.',
    'drag_and_drop',
    'intermediate',
    0,
    0,
    0,
    15,
    'published',
    true,
    2,
    0
  ),
  (
    'coc2_m3',
    'coc2',
    'ELC724332',
    3,
    'Test Cable Connectivity',
    'Use LAN tester simulation to verify cable connections and identify faults.',
    'step_procedure',
    'beginner',
    0,
    0,
    0,
    10,
    'published',
    true,
    3,
    0
  ),
  (
    'coc2_m4',
    'coc2',
    'ELC724332',
    4,
    'Connect Devices in Local Area Network',
    'Connect computers, switches, routers, and modems to create a functional LAN.',
    'drag_and_drop',
    'advanced',
    0,
    0,
    0,
    20,
    'published',
    true,
    4,
    0
  ),
  (
    'coc2_m5',
    'coc2',
    'ELC724332',
    5,
    'Configure IP Settings and Test Connection',
    'Set up IP address, subnet mask, gateway, and DNS, then test network connectivity.',
    'configuration_form',
    'advanced',
    0,
    0,
    0,
    20,
    'published',
    true,
    5,
    0
  ),
  (
    'coc3_m1',
    'coc3',
    'ELC724333',
    1,
    'Prepare Server Setup Requirements',
    'Identify and select required hardware, software, and documentation for server setup.',
    'identification',
    'intermediate',
    0,
    0,
    0,
    15,
    'published',
    true,
    1,
    0
  ),
  (
    'coc3_m2',
    'coc3',
    'ELC724333',
    2,
    'Install and Configure Server OS',
    'Follow step-by-step installation process for server operating system.',
    'step_procedure',
    'advanced',
    0,
    0,
    0,
    25,
    'published',
    true,
    2,
    0
  ),
  (
    'coc3_m3',
    'coc3',
    'ELC724333',
    3,
    'Configure Server Network Settings',
    'Set up static IP, subnet mask, gateway, and DNS for server network configuration.',
    'configuration_form',
    'advanced',
    0,
    0,
    0,
    20,
    'published',
    true,
    3,
    0
  ),
  (
    'coc3_m4',
    'coc3',
    'ELC724333',
    4,
    'Create Users, Groups, and Permissions',
    'Manage user accounts, groups, shared folders, and access permissions on the server.',
    'configuration_form',
    'advanced',
    0,
    0,
    0,
    25,
    'published',
    true,
    4,
    0
  ),
  (
    'coc3_m5',
    'coc3',
    'ELC724333',
    5,
    'Test Client Access and Document Setup',
    'Verify client connections and complete server setup documentation.',
    'troubleshooting',
    'intermediate',
    0,
    0,
    0,
    20,
    'published',
    true,
    5,
    0
  ),
  (
    'coc4_m1',
    'coc4',
    'ELC724334',
    1,
    'Identify System and Network Problems',
    'Match symptoms to their causes in computer and network troubleshooting scenarios.',
    'identification',
    'intermediate',
    0,
    0,
    0,
    15,
    'published',
    true,
    1,
    0
  ),
  (
    'coc4_m2',
    'coc4',
    'ELC724334',
    2,
    'Perform Preventive Maintenance',
    'Follow proper procedures for cleaning, inspecting, and maintaining computer systems.',
    'step_procedure',
    'intermediate',
    0,
    0,
    0,
    20,
    'published',
    true,
    2,
    0
  ),
  (
    'coc4_m3',
    'coc4',
    'ELC724334',
    3,
    'Diagnose Hardware and Software Faults',
    'Use diagnostic decision trees to identify hardware and software problems.',
    'troubleshooting',
    'advanced',
    0,
    0,
    0,
    25,
    'published',
    true,
    3,
    0
  ),
  (
    'coc4_m4',
    'coc4',
    'ELC724334',
    4,
    'Troubleshoot Network Issues',
    'Follow logical troubleshooting steps to resolve network connectivity problems.',
    'troubleshooting',
    'advanced',
    0,
    0,
    0,
    20,
    'published',
    true,
    4,
    0
  ),
  (
    'coc4_m5',
    'coc4',
    'ELC724334',
    5,
    'Apply Repair Action and Create Report',
    'Select correct repair solutions and document the troubleshooting process.',
    'troubleshooting',
    'advanced',
    0,
    0,
    0,
    25,
    'published',
    true,
    5,
    0
  );

insert into public.missions (
  coc_id,
  competency_id,
  mission_code,
  mission_number,
  title,
  description,
  mission_type,
  difficulty,
  xp_reward,
  points_reward,
  passing_score,
  estimated_time_minutes,
  status,
  is_locked,
  order_index,
  hint_count
)
select
  module.id,
  competency.id,
  seed.mission_code,
  seed.mission_number,
  seed.title,
  seed.description,
  seed.mission_type::public.mission_type,
  seed.difficulty,
  seed.xp_reward,
  seed.points_reward,
  seed.passing_score,
  seed.estimated_time_minutes,
  seed.status::public.mission_status,
  seed.is_locked,
  seed.order_index,
  seed.hint_count
from pg_temp.bytequest_catalog_missions seed
join public.coc_modules module
  on module.coc_code = seed.coc_code
join public.competencies competency
  on competency.competency_code = seed.competency_code
on conflict do nothing;

do $$
begin
  if exists (
    select 1
    from pg_temp.bytequest_catalog_competencies seed
    left join public.competencies competency
      on competency.competency_code = seed.competency_code
    where competency.id is null
      or competency.name <> seed.name
      or competency.order_index <> seed.order_index
  ) then
    raise exception
      'ByteQuest competency catalog conflicts with the approved four-row manifest.';
  end if;

  if exists (
    select 1
    from pg_temp.bytequest_catalog_modules seed
    left join public.coc_modules module
      on module.coc_code = seed.coc_code
    left join public.competencies competency
      on competency.competency_code = seed.competency_code
    where module.id is null
      or competency.id is null
      or module.competency_id is distinct from competency.id
      or module.title <> seed.title
      or module.module_name <> seed.module_name
      or module.competency_area is distinct from seed.competency_area
      or module.total_missions <> seed.total_missions
      or module.order_index <> seed.order_index
      or module.status::text <> seed.status
      or module.difficulty <> seed.difficulty
  ) then
    raise exception
      'ByteQuest COC module catalog conflicts with the approved four-row manifest.';
  end if;

  if exists (
    select 1
    from pg_temp.bytequest_catalog_missions seed
    left join public.missions mission
      on mission.mission_code = seed.mission_code
    left join public.coc_modules module
      on module.coc_code = seed.coc_code
    left join public.competencies competency
      on competency.competency_code = seed.competency_code
    where mission.id is null
      or module.id is null
      or competency.id is null
      or mission.coc_id is distinct from module.id
      or mission.competency_id is distinct from competency.id
      or mission.mission_number <> seed.mission_number
      or mission.title <> seed.title
      or mission.description is distinct from seed.description
      or mission.mission_type::text <> seed.mission_type
      or mission.difficulty <> seed.difficulty
      or mission.passing_score <> seed.passing_score
      or mission.estimated_time_minutes <> seed.estimated_time_minutes
      or mission.status::text <> seed.status
      or mission.is_locked <> seed.is_locked
      or mission.order_index <> seed.order_index
      or mission.hint_count <> seed.hint_count
  ) then
    raise exception
      'ByteQuest mission catalog conflicts with the approved twenty-row manifest.';
  end if;
end
$$;

commit;
