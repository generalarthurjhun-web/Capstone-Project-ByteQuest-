part of '../mission_simulation_definitions.dart';

final List<MissionSimulationDefinition> _coc3Definitions = [
  _mission(
    id: 'coc3_m1',
    title: 'Prepare a Server Workspace',
    scenario: 'Validate a server workspace before installation begins.',
    environmentLabel: 'Server preparation room',
    practiceGuidance:
        'Inspect requirements and readiness before recording the preparation sequence.',
    objects: const {
      'server_chassis': 'Server chassis',
      'network_drop': 'Network drop',
      'power_conditioner': 'Power conditioner',
      'installation_media': 'Installation media',
      'setup_document': 'Setup document',
    },
    phases: [
      _phase(
          'Inspect workspace',
          'Inspect power, network, hardware, and documentation.',
          InteractionFamily.inspect,
          'inspect_workspace',
          presentation: const {'component': 'tap_inspect'}),
      _phase(
          'Identify requirements',
          'Record the hardware, software, and infrastructure requirements.',
          InteractionFamily.inspect,
          'identify_requirements',
          presentation: const {'component': 'multi_select'}),
      _phase(
          'Decide server role',
          'Choose the server role that fits the stated service request.',
          InteractionFamily.decide,
          'decide_server_role',
          presentation: const {'component': 'scenario_decision'}),
      _phase(
          'Check readiness',
          'Run the network and workspace readiness checks.',
          InteractionFamily.testRun,
          'check_readiness'),
      _phase(
          'Sequence preparation',
          'Record the final preparation actions chronologically.',
          InteractionFamily.inspect,
          'sequence_preparation',
          presentation: const {'component': 'sequencing'}),
      _phase(
          'Review evidence',
          'Review requirements, role, readiness, and sequence evidence.',
          InteractionFamily.review,
          'review_evidence'),
    ],
  ),
  _mission(
    id: 'coc3_m2',
    title: 'Install and Configure a Server OS',
    scenario: 'Install a server operating system for a defined service role.',
    environmentLabel: 'Server installation console',
    practiceGuidance:
        'Record role and configuration choices before starting the simulated installation.',
    objects: const {
      'server': 'Server',
      'installation_media': 'Installation media',
      'role_console': 'Role configuration',
      'service_monitor': 'Service monitor',
    },
    phases: [
      _phase(
          'Decide roles and configuration',
          'Record server-role and base-configuration decisions.',
          InteractionFamily.decide,
          'decide_roles_and_config',
          presentation: const {'component': 'configuration_decision'}),
      _phase('Simulate installation', 'Run the recorded installation sequence.',
          InteractionFamily.configure, 'simulate_install',
          presentation: const {'component': 'sequencing'}),
      _phase(
          'Simulate restart',
          'Restart the simulated server and observe its state transition.',
          InteractionFamily.configure,
          'simulate_restart',
          presentation: const {'action_type': 'server_restart_requested'}),
      _phase('Verify services', 'Run service-readiness checks after restart.',
          InteractionFamily.testRun, 'verify_services'),
      _phase(
          'Review evidence',
          'Review role, installation, restart, and readiness evidence.',
          InteractionFamily.review,
          'review_evidence'),
    ],
  ),
  _mission(
    id: 'coc3_m3',
    title: 'Configure Accounts and Permissions',
    scenario: 'Prepare role-based access for a shared server resource.',
    environmentLabel: 'Identity and access console',
    practiceGuidance:
        'Preserve account, group, permission, and access-test evidence as separate records.',
    objects: const {
      'account_console': 'Account console',
      'group_console': 'Group console',
      'shared_folder': 'Shared folder',
      'client_session': 'Client session',
    },
    phases: [
      _phase(
          'Configure accounts, groups, and permissions',
          'Create identity records and assign resource permissions.',
          InteractionFamily.troubleshoot,
          'configure_accounts_groups_permissions',
          presentation: const {'component': 'configuration'}),
      _phase(
          'Inspect access',
          'Inspect the effective access shown for the client session.',
          InteractionFamily.troubleshoot,
          'inspect_access'),
      _phase(
          'Test access',
          'Run the client access test and preserve its output.',
          InteractionFamily.testRun,
          'test_access'),
      _phase(
        'Diagnose permission',
        'Reveal identity and resource facts before changing access.',
        InteractionFamily.troubleshoot,
        'diagnose_permission',
        presentation: _progressiveDiagnostics(
          symptom:
              'A client session cannot complete the requested resource action.',
          actions: const [
            (
              'inspect_group_membership',
              'Inspect group membership',
              'group_membership_fact',
              'The client session lists the Learners group but does not list the Support group.'
            ),
            (
              'inspect_effective_permission',
              'Inspect effective permission',
              'effective_permission_fact',
              'Effective access reports Read allowed and Modify not granted for the shared folder.'
            ),
            (
              'inspect_resource_scope',
              'Inspect resource scope',
              'resource_scope_fact',
              'The share lists Support with Change access and Learners with Read access.'
            ),
          ],
        ),
      ),
      _phase(
        'Correct access',
        'Apply the supported permission correction and repeat the access check.',
        InteractionFamily.decide,
        'correct_access',
        presentation: const {
          'correction': {
            'id': 'apply_permission_change',
            'label': 'Apply the supported permission change',
          },
          'retest': {
            'id': 'retest_client_access',
            'label': 'Repeat the client access check',
          },
        },
      ),
      _phase(
          'Review evidence',
          'Review identity configuration, diagnosis, correction, and access evidence.',
          InteractionFamily.review,
          'review_evidence'),
    ],
  ),
  _mission(
    id: 'coc3_m4',
    title: 'Configure and Operate Server Services',
    scenario: 'Configure a server service and verify access from a client.',
    environmentLabel: 'Service administration console',
    practiceGuidance:
        'Record configuration and status transitions before running the client test.',
    objects: const {
      'server': 'Server',
      'service_console': 'Service console',
      'status_monitor': 'Status monitor',
      'client': 'Client workstation',
    },
    phases: [
      _phase(
          'Inspect service',
          'Inspect installed service state and configuration surfaces.',
          InteractionFamily.configure,
          'inspect_service'),
      _phase(
          'Configure service',
          'Record service values and operating settings.',
          InteractionFamily.configure,
          'configure_service',
          presentation: const {'component': 'configuration'}),
      _phase(
          'Start, stop, and inspect status',
          'Record service controls and the resulting status.',
          InteractionFamily.configure,
          'start_stop_status',
          presentation: const {'component': 'service_controls'}),
      _phase(
          'Test client access',
          'Run the client request against the configured service.',
          InteractionFamily.testRun,
          'test_client_access'),
      _phase(
          'Interpret response',
          'Record a technical interpretation of the client response.',
          InteractionFamily.decide,
          'interpret_response',
          presentation: const {'component': 'result_interpretation'}),
      _phase(
          'Review evidence',
          'Review service configuration, status, client test, and interpretation.',
          InteractionFamily.review,
          'review_evidence'),
    ],
  ),
  _mission(
    id: 'coc3_m5',
    title: 'Recover Client-Server Access',
    scenario:
        'A client loses access to a previously available server resource.',
    environmentLabel: 'Client-server recovery console',
    practiceGuidance:
        'Inspect each layer progressively and unlock correction only after earning facts.',
    objects: const {
      'client': 'Client',
      'server': 'Server',
      'service': 'Service',
      'network_path': 'Network path',
      'permission_scope': 'Permission scope',
    },
    phases: [
      _phase(
          'Inspect client and server',
          'Inspect visible client and server state.',
          InteractionFamily.troubleshoot,
          'inspect_client_and_server'),
      _phase(
          'Inspect service and configuration',
          'Inspect service, connectivity, and permission surfaces.',
          InteractionFamily.troubleshoot,
          'inspect_service_and_config'),
      _phase(
        'Troubleshoot connectivity and permissions',
        'Reveal one client-server fact for each diagnostic action.',
        InteractionFamily.troubleshoot,
        'troubleshoot_connectivity_permissions',
        presentation: _progressiveDiagnostics(
          symptom: 'The client cannot use the requested server resource.',
          actions: const [
            (
              'probe_client_network',
              'Probe client network',
              'client_network_fact',
              'The client ping receives four replies from the server address below 2 ms.'
            ),
            (
              'inspect_service_status',
              'Inspect service status',
              'service_status_fact',
              'The file service reports Running with TCP port 445 listening.'
            ),
            (
              'inspect_access_scope',
              'Inspect access scope',
              'access_scope_fact',
              'The client token lists Learners, while the share access list grants Change to Support.'
            ),
          ],
        ),
      ),
      _phase(
        'Correct fault',
        'Apply the correction supported by the earned facts.',
        InteractionFamily.decide,
        'correct_fault',
        presentation: const {
          'correction': {
            'id': 'apply_service_recovery',
            'label': 'Apply the supported recovery action',
          },
        },
      ),
      _phase(
        'Retest recovery',
        'Run client access and service recovery checks.',
        InteractionFamily.testRun,
        'retest_recovery',
        presentation: const {
          'retest': {
            'id': 'retest_service_access',
            'label': 'Retest client access to the service',
          },
        },
      ),
      _phase(
          'Review evidence',
          'Review inspection, diagnostics, correction, and recovery evidence.',
          InteractionFamily.review,
          'review_evidence'),
    ],
  ),
];
