part of '../mission_simulation_definitions.dart';

final List<MissionSimulationDefinition> _coc3Definitions = [
  _mission(
    id: 'coc3_m1',
    title: 'Prepare Server Setup Requirements',
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
          presentation: const {
            'component': 'scenario_decision',
            'choices': [
              {
                'id': 'record_server_requirements',
                'label':
                    'Record power, network, storage, and installation-media requirements',
              },
              {
                'id': 'escalate_missing_requirements',
                'label':
                    'Escalate incomplete infrastructure requirements before installation',
              },
            ],
          }),
      _phase(
          'Decide server role',
          'Choose the server role that fits the stated service request.',
          InteractionFamily.decide,
          'decide_server_role',
          presentation: const {
            'component': 'scenario_decision',
            'choices': [
              {'id': 'file_service', 'label': 'File and access service'},
              {
                'id': 'network_service',
                'label': 'Network infrastructure service'
              },
              {'id': 'application_service', 'label': 'Application service'},
            ],
          }),
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
    title: 'Install and Configure Server OS',
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
          presentation: const {
            'component': 'configuration_decision',
            'fields': [
              {
                'id': 'server_role',
                'label': 'Server role',
                'type': 'dropdown',
                'options': [
                  {'id': 'file_service', 'label': 'File service'},
                  {'id': 'directory_service', 'label': 'Directory service'},
                  {'id': 'network_service', 'label': 'Network service'},
                ],
              },
              {'id': 'host_name', 'label': 'Server host name'},
              {'id': 'management_address', 'label': 'Management address'},
            ],
          }),
      _phase('Simulate installation', 'Run the recorded installation sequence.',
          InteractionFamily.configure, 'simulate_install',
          presentation: const {'component': 'sequencing'}),
      _phase(
          'Simulate restart',
          'Restart the simulated server and observe its state transition.',
          InteractionFamily.configure,
          'simulate_restart',
          presentation: const {
            'component': 'scenario_decision',
            'action_type': 'server_restart_requested',
            'choices': [
              {
                'id': 'restart_after_configuration',
                'label': 'Restart after saving the recorded configuration',
              },
              {
                'id': 'defer_restart',
                'label': 'Defer restart and review pending configuration',
              },
            ],
          }),
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
    title: 'Configure Server Network Settings',
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
          presentation: const {
            'component': 'configuration',
            'fields': [
              {'id': 'account_name', 'label': 'Account name'},
              {
                'id': 'group_assignment',
                'label': 'Group assignment',
                'type': 'dropdown',
                'options': [
                  {'id': 'learners', 'label': 'Learners'},
                  {'id': 'support', 'label': 'Support'},
                ],
              },
              {
                'id': 'resource_permission',
                'label': 'Resource permission',
                'type': 'dropdown',
                'options': [
                  {'id': 'read', 'label': 'Read'},
                  {'id': 'modify', 'label': 'Modify'},
                ],
              },
            ],
          }),
      _phase(
          'Inspect and test access',
          'Inspect effective access, then run the client access test.',
          InteractionFamily.testRun,
          'inspect_and_test_access'),
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
          'choices': [
            {
              'id': 'apply_permission_change',
              'label': 'Apply the supported permission change',
            },
          ],
        },
      ),
      _phase(
        'Retest client access',
        'Repeat the client access check after the permission change.',
        InteractionFamily.testRun,
        'retest_client_access',
        presentation: const {
          'evidenceActionType': 'retest_requested',
          'target': 'retest_client_access',
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
    title: 'Create Users, Groups, and Permissions',
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
          'inspect_service',
          presentation: const {'component': 'tap_inspect'}),
      _phase(
          'Configure service',
          'Record service values and operating settings.',
          InteractionFamily.configure,
          'configure_service',
          presentation: const {
            'component': 'configuration',
            'fields': [
              {'id': 'service_name', 'label': 'Service name'},
              {'id': 'listen_port', 'label': 'Listening port'},
              {
                'id': 'startup_mode',
                'label': 'Startup mode',
                'type': 'dropdown',
                'options': [
                  {'id': 'automatic', 'label': 'Automatic'},
                  {'id': 'manual', 'label': 'Manual'},
                ],
              },
            ],
          }),
      _phase(
          'Start, stop, and inspect status',
          'Record service controls and the resulting status.',
          InteractionFamily.configure,
          'start_stop_status',
          presentation: const {
            'component': 'service_controls',
            'fields': [
              {
                'id': 'service_control',
                'label': 'Service control',
                'type': 'dropdown',
                'options': [
                  {'id': 'start', 'label': 'Start service'},
                  {'id': 'stop', 'label': 'Stop service'},
                  {'id': 'restart', 'label': 'Restart service'},
                ],
              },
              {
                'id': 'status_inspected',
                'label': 'Resulting status inspected',
                'type': 'toggle',
              },
            ],
          }),
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
    title: 'Test Client Access and Document Setup',
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
          'inspect_client_and_server',
          presentation: _progressiveDiagnostics(
            symptom:
                'A client has lost access to a previously available server resource.',
            actions: const [
              (
                'inspect_client_message',
                'Inspect client message',
                'client_message_fact',
                'The client reports Access denied while the server name resolves to 192.168.30.10.'
              ),
              (
                'inspect_server_console',
                'Inspect server console',
                'server_console_fact',
                'The server console reports the file service Running with no active storage warning.'
              ),
            ],
          )),
      _phase(
          'Inspect service and configuration',
          'Inspect service, connectivity, and permission surfaces.',
          InteractionFamily.troubleshoot,
          'inspect_service_and_config',
          presentation: _progressiveDiagnostics(
            symptom:
                'Determine whether the interruption is caused by the service, network path, or access scope.',
            actions: const [
              (
                'inspect_listener_state',
                'Inspect listener state',
                'listener_state_fact',
                'The service monitor lists TCP port 445 as Listening on the server address.'
              ),
              (
                'inspect_permission_summary',
                'Inspect permission summary',
                'permission_summary_fact',
                'The share permission summary grants Change to Support and Read to Learners.'
              ),
            ],
          )),
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
          'choices': [
            {
              'id': 'apply_service_recovery',
              'label': 'Apply the supported recovery action',
            },
          ],
        },
      ),
      _phase(
        'Retest recovery',
        'Run client access and service recovery checks.',
        InteractionFamily.testRun,
        'retest_recovery',
        presentation: const {
          'evidenceActionType': 'retest_requested',
          'target': 'retest_service_access',
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
