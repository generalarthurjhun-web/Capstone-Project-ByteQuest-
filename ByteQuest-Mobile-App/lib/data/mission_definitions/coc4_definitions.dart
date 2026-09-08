part of '../mission_simulation_definitions.dart';

final List<MissionSimulationDefinition> _coc4Definitions = [
  _mission(
    id: 'coc4_m1',
    title: 'Identify System and Network Problems',
    scenario: 'Triage a workstation with a reported system or network symptom.',
    environmentLabel: 'Diagnostic intake station',
    practiceGuidance:
        'Separate inspected observations from the preliminary diagnostic decision.',
    objects: const {
      'workstation': 'Workstation',
      'display': 'Display',
      'network_adapter': 'Network adapter',
      'event_console': 'Event console',
    },
    phases: [
      _phase(
          'Inspect environment and components',
          'Inspect the work area and relevant components.',
          InteractionFamily.inspect,
          'inspect_environment_components',
          presentation: const {'component': 'tap_inspect'}),
      _phase(
          'Record symptom observation',
          'Record only the visible or reported condition.',
          InteractionFamily.inspect,
          'record_symptom_observation',
          presentation: const {'component': 'observation'}),
      _phase(
          'Prioritize diagnostics',
          'Choose the next diagnostic priority from the available evidence.',
          InteractionFamily.decide,
          'prioritize_diagnostics',
          presentation: const {
            'component': 'scenario_decision',
            'choices': [
              {
                'id': 'prioritize_power_and_display',
                'label': 'Prioritize power and display signal checks',
              },
              {
                'id': 'prioritize_network_path',
                'label': 'Prioritize physical and logical network-path checks',
              },
            ],
          }),
      _phase(
          'State preliminary diagnosis',
          'Record a preliminary diagnosis without claiming an untested root cause.',
          InteractionFamily.decide,
          'state_preliminary_diagnosis',
          presentation: const {
            'component': 'scenario_decision',
            'choices': [
              {
                'id': 'preliminary_hardware_path',
                'label': 'Record a preliminary hardware-path diagnosis',
              },
              {
                'id': 'preliminary_network_path',
                'label': 'Record a preliminary network-path diagnosis',
              },
            ],
          }),
      _phase(
          'Verify diagnosis',
          'Run a verification check against the preliminary diagnosis.',
          InteractionFamily.testRun,
          'verify_diagnosis'),
      _phase(
          'Review evidence',
          'Review inspection, observation, priority, diagnosis, and verification.',
          InteractionFamily.review,
          'review_evidence'),
    ],
  ),
  _mission(
    id: 'coc4_m2',
    title: 'Perform Preventive Maintenance',
    scenario:
        'A workstation component reports an intermittent operating fault.',
    environmentLabel: 'Hardware diagnostic bay',
    practiceGuidance:
        'Use measured results to support the fault decision and repair action.',
    objects: const {
      'workstation': 'Workstation',
      'memory_module': 'Memory module',
      'storage_drive': 'Storage drive',
      'power_supply': 'Power supply',
      'diagnostic_tool': 'Diagnostic tool',
    },
    phases: [
      _phase(
          'Inspect symptom and component',
          'Inspect the reported symptom and component condition.',
          InteractionFamily.troubleshoot,
          'inspect_symptom_component',
          presentation: _progressiveDiagnostics(
            symptom:
                'The workstation intermittently stops during sustained operation.',
            actions: const [
              (
                'inspect_component_seating',
                'Inspect component seating',
                'component_seating_fact',
                'The memory latches are fully closed and the storage connector is seated without visible damage.'
              ),
              (
                'inspect_event_indicator',
                'Inspect event indicator',
                'event_indicator_fact',
                'The system event indicator records repeated storage retry warnings before each stop.'
              ),
            ],
          )),
      _phase(
        'Select tool and run test',
        'Choose diagnostic actions that measure the inspected condition.',
        InteractionFamily.troubleshoot,
        'select_tool_and_test',
        presentation: _progressiveDiagnostics(
          symptom: 'The workstation intermittently stops during operation.',
          actions: const [
            (
              'run_memory_probe',
              'Run memory probe',
              'memory_probe_fact',
              'The memory probe completes two passes with 0 reported errors.'
            ),
            (
              'inspect_storage_health',
              'Inspect storage health',
              'storage_health_fact',
              'The storage health monitor reports Caution with 18 pending sectors.'
            ),
            (
              'measure_power_state',
              'Measure power state',
              'power_state_fact',
              'The power meter measures 12.1 V and 5.02 V on the supply rails under load.'
            ),
          ],
        ),
      ),
      _phase('Interpret result', 'Record what the measured result indicates.',
          InteractionFamily.decide, 'interpret_result',
          presentation: const {'component': 'result_interpretation'}),
      _phase(
          'Identify fault',
          'Record the supported fault category and select the repair action.',
          InteractionFamily.decide,
          'identify_fault',
          presentation: const {
            'choices': [
              {
                'id': 'apply_component_repair',
                'label': 'Apply the supported component repair',
              },
            ],
          }),
      _phase(
        'Repair and verify',
        'Record the repair and run the post-repair verification.',
        InteractionFamily.testRun,
        'repair_and_verify',
        presentation: const {
          'evidenceActionType': 'retest_requested',
          'target': 'retest_component',
        },
      ),
      _phase(
          'Review evidence',
          'Review inspection, diagnostics, interpretation, and repair evidence.',
          InteractionFamily.review,
          'review_evidence'),
    ],
  ),
  _mission(
    id: 'coc4_m3',
    title: 'Diagnose Hardware and Software Faults',
    scenario:
        'A workstation has application and network symptoms with no confirmed root cause.',
    environmentLabel: 'Software and network diagnostic console',
    practiceGuidance:
        'Interpret each earned result before continuing; the catalog exposes no early root cause.',
    objects: const {
      'workstation': 'Workstation',
      'application_log': 'Application log',
      'service_monitor': 'Service monitor',
      'network_interface': 'Network interface',
      'route_monitor': 'Route monitor',
    },
    phases: [
      _phase(
          'Inspect symptoms',
          'Inspect only the initial software and network symptoms.',
          InteractionFamily.troubleshoot,
          'inspect_symptoms',
          presentation: const {'component': 'tap_inspect'}),
      _phase(
        'Run software diagnostic',
        'Choose a software diagnostic to reveal one recorded fact.',
        InteractionFamily.troubleshoot,
        'run_software_diagnostic',
        presentation: const {
          'diagnostic_actions': [
            {
              'id': 'inspect_application_log',
              'label': 'Inspect application log',
              'reveals_fact_id': 'application_log_fact'
            },
          ],
          'facts': {
            'application_log_fact':
                'The application log records three request timeouts at 14:02:18.',
          },
          'required_fact_ids': ['application_log_fact'],
        },
      ),
      _phase(
          'Interpret software result',
          'Interpret the earned software facts before opening network diagnostics.',
          InteractionFamily.decide,
          'interpret_software_result',
          presentation: const {
            'component': 'result_interpretation',
            'source_fact_ids': ['application_log_fact'],
          }),
      _phase(
        'Run network diagnostic',
        'Choose a network diagnostic and preserve its displayed result.',
        InteractionFamily.testRun,
        'run_network_diagnostic',
        presentation: const {
          'diagnostic_actions': [
            {
              'id': 'run_route_trace',
              'label': 'Run route trace',
              'reveals_fact_id': 'route_trace_fact'
            },
          ],
          'facts': {
            'route_trace_fact':
                'The route trace reaches gateway 192.168.1.1, then times out at hop 2.',
          },
          'required_fact_ids': ['route_trace_fact'],
        },
      ),
      _phase(
          'Interpret network result',
          'Interpret the earned network facts without revealing a catalog answer.',
          InteractionFamily.decide,
          'interpret_network_result',
          presentation: const {
            'component': 'result_interpretation',
            'source_fact_ids': ['route_trace_fact'],
          }),
      _phase(
          'Review evidence',
          'Review the diagnostic order and both recorded interpretations.',
          InteractionFamily.review,
          'review_evidence'),
    ],
  ),
  _mission(
    id: 'coc4_m4',
    title: 'Troubleshoot Network Issues',
    scenario:
        'Replace a diagnosed component and restore its operating configuration.',
    environmentLabel: 'Repair and replacement bench',
    practiceGuidance:
        'Select compatible parts and tools, then use accessible controlled placement.',
    objects: const {
      'workstation': 'Workstation',
      'replacement_component': 'Replacement component',
      'service_tool': 'Service tool',
      'configuration_console': 'Configuration console',
    },
    phases: [
      _phase(
          'Select component and tool',
          'Inspect and select a compatible component and service tool.',
          InteractionFamily.place,
          'select_component_tool',
          presentation: const {
            'component': 'controlled_placement',
            'items': [
              {
                'id': 'replacement_component',
                'label': 'Replacement component',
                'category': 'service_part',
                'orientations': ['aligned', 'rotated'],
              },
            ],
            'destinations': [
              {
                'id': 'workstation',
                'label': 'Service location',
              },
            ],
          }),
      _phase(
        'Replace accessibly',
        'Select the component, destination, and orientation, then confirm placement.',
        InteractionFamily.place,
        'replace_accessibly',
        presentation: const {
          'component': 'controlled_placement',
          'accessibleControl': 'select_then_confirm',
          'items': [
            {
              'id': 'replacement_component',
              'label': 'Replacement component',
              'category': 'service_part'
            },
          ],
          'destinations': [
            {'id': 'workstation', 'label': 'Service location'},
          ],
          'orientations': ['aligned', 'rotated'],
        },
      ),
      _phase(
          'Reconfigure component',
          'Record the replacement component configuration.',
          InteractionFamily.decide,
          'reconfigure_component',
          presentation: const {
            'component': 'configuration',
            'fields': [
              {'id': 'device_mode', 'label': 'Replacement device mode'},
              {'id': 'device_identifier', 'label': 'Device identifier'},
              {
                'id': 'driver_state',
                'label': 'Driver state',
                'type': 'dropdown',
                'options': [
                  {'id': 'installed', 'label': 'Installed'},
                  {'id': 'pending_restart', 'label': 'Pending restart'},
                ],
              },
            ],
          }),
      _phase(
          'Sequence repair',
          'Record removal, replacement, fastening, and close-out actions.',
          InteractionFamily.place,
          'sequence_repair',
          presentation: const {'component': 'sequencing'}),
      _phase('Run post-repair test', 'Run the post-repair functional test.',
          InteractionFamily.testRun, 'run_post_repair_test'),
      _phase(
          'Review evidence',
          'Review selection, replacement, configuration, sequence, and test evidence.',
          InteractionFamily.review,
          'review_evidence'),
    ],
  ),
  _mission(
    id: 'coc4_m5',
    title: 'Apply Repair Action and Create Report',
    scenario:
        'Complete a prioritized maintenance request and prepare its service report.',
    environmentLabel: 'Maintenance and reporting station',
    practiceGuidance:
        'Tie each maintenance or repair action to an inspected issue and recorded test.',
    objects: const {
      'service_request': 'Service request',
      'workstation': 'Workstation',
      'maintenance_tool': 'Maintenance tool',
      'configuration_console': 'Configuration console',
      'service_report': 'Service report',
    },
    phases: [
      _phase(
          'Inspect request and system',
          'Inspect all five service requests before selecting diagnostic actions.',
          InteractionFamily.troubleshoot,
          'inspect_request_system',
          presentation: _coc4M5ServiceDiagnostics()),
      _phase(
        'Prioritize issue and tool',
        'Use the recorded findings to select the next safe service action.',
        InteractionFamily.decide,
        'prioritize_issue_and_tool',
        presentation: const {
          'choices': [
            {
              'id': 'service_verified_faults',
              'label': 'Service the faults supported by diagnostic evidence',
            },
            {
              'id': 'replace_unverified_hardware',
              'label': 'Replace hardware without isolating the cause',
            },
            {
              'id': 'close_requests_without_test',
              'label': 'Close all requests without corrective action',
            },
          ],
        },
      ),
      _phase(
        'Maintain and repair configuration',
        'Record maintenance, repair, and configuration actions.',
        InteractionFamily.decide,
        'maintain_repair_config',
        presentation: const {
          'choices': [
            {
              'id': 'approve_maintenance_action',
              'label': 'Record the prioritized maintenance action',
            },
          ],
        },
      ),
      _phase(
        'Test and interpret',
        'Run the service test and record an interpretation.',
        InteractionFamily.testRun,
        'test_and_interpret',
        presentation: const {
          'component': 'test_with_interpretation',
          'requires_interpretation': true,
          'evidenceActionType': 'retest_requested',
          'target': 'run_maintenance_check',
        },
      ),
      _phase(
          'Final verify',
          'Verify system condition and complete the service report.',
          InteractionFamily.troubleshoot,
          'final_verify',
          presentation: const {'component': 'observation'}),
      _phase(
          'Review evidence',
          'Review request, maintenance, test, verification, and report evidence.',
          InteractionFamily.review,
          'review_evidence'),
    ],
  ),
];
