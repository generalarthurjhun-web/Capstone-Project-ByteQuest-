part of '../mission_simulation_definitions.dart';

final List<MissionSimulationDefinition> _coc2Definitions = [
  _mission(
    id: 'coc2_m1',
    title: 'Prepare and Test Network Cabling',
    scenario: 'Prepare a cable run for a small workstation network.',
    environmentLabel: 'Network cabling bench',
    practiceGuidance:
        'Record materials, tools, preparation, and connection evidence before testing.',
    objects: const {
      'copper_cable': 'Copper network cable',
      'rj45_connector': 'RJ45 connector',
      'wire_stripper': 'Wire stripper',
      'crimping_tool': 'Crimping tool',
      'lan_cable_tester': 'LAN cable tester',
    },
    phases: [
      _phase(
          'Identify materials',
          'Inspect and identify the available network materials.',
          InteractionFamily.connect,
          'identify_materials',
          presentation: const {'component': 'tap_inspect'}),
      _phase(
          'Select tools',
          'Select the tools needed for the planned cable work.',
          InteractionFamily.decide,
          'select_tools',
          presentation: const {'component': 'tool_selection'}),
      _phase(
          'Sequence preparation',
          'Record the cable-preparation actions chronologically.',
          InteractionFamily.connect,
          'sequence_preparation',
          presentation: const {'component': 'sequencing'}),
      _phase(
        'Connect cable',
        'Select the cable endpoint and then confirm its destination.',
        InteractionFamily.connect,
        'connect_cable',
        presentation: const {
          'component': 'connection',
          'accessibleControl': 'select_then_confirm',
          'sources': [
            {'id': 'copper_cable', 'label': 'Prepared cable endpoint'},
          ],
          'destinations': [
            {'id': 'lan_cable_tester', 'label': 'Cable tester port'},
          ],
        },
      ),
      _phase(
          'Test and interpret',
          'Run the cable test and record an interpretation of the indicators.',
          InteractionFamily.testRun,
          'test_and_interpret',
          presentation: const {'component': 'test_with_interpretation'}),
      _phase(
          'Review evidence',
          'Review material, preparation, connection, and tester evidence.',
          InteractionFamily.review,
          'review_evidence'),
    ],
  ),
  _mission(
    id: 'coc2_m2',
    title: 'Build a Standards-Based Network Link',
    scenario:
        'Prepare a standards-based cable and use it in a device topology.',
    environmentLabel: 'Cable and topology lab',
    practiceGuidance:
        'Use the published cable evidence identifiers while keeping evaluator rules server-owned.',
    objects: const {
      'workstation': 'Workstation',
      'switch': 'Network switch',
      'router': 'Router',
      'copper_cable': 'Copper network cable',
      'lan_cable_tester': 'LAN cable tester',
    },
    phases: [
      _phase(
        'Inspect topology',
        'Inspect device ports and prepare personal protective equipment and tools.',
        InteractionFamily.connect,
        'inspect_topology',
        presentation: const {
          'component': 'tap_inspect',
          'evidence_actions': [
            {'action_type': 'ppe_selection_submitted'},
            {'action_type': 'tools_materials_selection_submitted'},
          ],
        },
      ),
      _phase(
        'Prepare golden cable',
        'Record preparation, conductor placement, and termination actions.',
        InteractionFamily.connect,
        'prepare_golden_cable',
        presentation: const {
          'component': 'sequencing_and_placement',
          'accessibleControl': 'select_then_confirm',
          'evidence_actions': [
            {'action_type': 'cable_preparation_step'},
            {'action_type': 'conductor_placed'},
            {'action_type': 'termination_step'},
          ],
          'conductors': [
            {'id': 'blue', 'label': 'Blue'},
            {'id': 'brown', 'label': 'Brown'},
            {'id': 'green', 'label': 'Green'},
            {'id': 'orange', 'label': 'Orange'},
            {'id': 'white_blue', 'label': 'White–Blue'},
            {'id': 'white_brown', 'label': 'White–Brown'},
            {'id': 'white_green', 'label': 'White–Green'},
            {'id': 'white_orange', 'label': 'White–Orange'},
          ],
        },
      ),
      _phase(
        'Connect devices accessibly',
        'Select each source and destination to create topology links.',
        InteractionFamily.connect,
        'connect_accessibly',
        presentation: const {
          'component': 'connection',
          'accessibleControl': 'select_then_confirm',
          'sources': [
            {'id': 'workstation', 'label': 'Workstation'},
            {'id': 'switch', 'label': 'Network switch'},
          ],
          'destinations': [
            {'id': 'switch', 'label': 'Network switch'},
            {'id': 'router', 'label': 'Router'},
          ],
        },
      ),
      _phase(
        'Configure devices',
        'Record interface configuration and physical inspection evidence.',
        InteractionFamily.decide,
        'configure_devices',
        presentation: const {
          'component': 'configuration',
          'evidence_actions': [
            {'action_type': 'inspection_selection_submitted'},
          ],
        },
      ),
      _phase(
        'Verify connectivity',
        'Operate the tester, record its result, and close the work area.',
        InteractionFamily.testRun,
        'verify_connectivity',
        presentation: const {
          'component': 'test_run',
          'evidence_actions': [
            {'action_type': 'tester_step'},
            {'action_type': 'tester_result_submitted'},
            {'action_type': 'cleanup_selection_submitted'},
          ],
        },
      ),
      _phase(
          'Review evidence',
          'Review cable, topology, configuration, and connectivity evidence.',
          InteractionFamily.review,
          'review_evidence'),
    ],
  ),
  _mission(
    id: 'coc2_m3',
    title: 'Construct a Network Topology',
    scenario: 'Build and validate a small multi-node topology.',
    environmentLabel: 'Topology workspace',
    practiceGuidance:
        'Select nodes and endpoints explicitly; every link can be created without dragging.',
    objects: const {
      'router': 'Router',
      'switch': 'Switch',
      'workstation_a': 'Workstation A',
      'workstation_b': 'Workstation B',
      'server': 'Server',
    },
    phases: [
      _phase(
          'Select nodes',
          'Select the devices required by the topology request.',
          InteractionFamily.connect,
          'select_nodes',
          presentation: const {'component': 'multi_select'}),
      _phase(
        'Connect topology',
        'Select a source and destination for each topology link.',
        InteractionFamily.connect,
        'connect_topology',
        presentation: const {
          'component': 'connection',
          'accessibleControl': 'select_then_confirm',
          'sources': [
            {'id': 'router', 'label': 'Router'},
            {'id': 'switch', 'label': 'Switch'},
            {'id': 'workstation_a', 'label': 'Workstation A'},
            {'id': 'workstation_b', 'label': 'Workstation B'},
          ],
          'destinations': [
            {'id': 'switch', 'label': 'Switch'},
            {'id': 'server', 'label': 'Server'},
          ],
        },
      ),
      _phase(
          'Test links',
          'Run link checks and preserve each displayed status.',
          InteractionFamily.connect,
          'test_links',
          presentation: const {'component': 'link_test'}),
      _phase(
          'Fix invalid link',
          'Choose and apply a repair for the recorded invalid link.',
          InteractionFamily.decide,
          'fix_invalid_link'),
      _phase(
          'Verify topology',
          'Run topology verification after the link repair.',
          InteractionFamily.testRun,
          'verify_topology'),
      _phase('Review evidence', 'Review node, link, test, and repair evidence.',
          InteractionFamily.review, 'review_evidence'),
    ],
  ),
  _mission(
    id: 'coc2_m4',
    title: 'Configure Network Devices',
    scenario: 'Configure a selected device and verify client connectivity.',
    environmentLabel: 'Device configuration console',
    practiceGuidance:
        'Keep device context with configuration values and preserve both test results.',
    objects: const {
      'router': 'Router',
      'switch': 'Managed switch',
      'workstation': 'Client workstation',
      'configuration_console': 'Configuration console',
    },
    phases: [
      _phase('Select device', 'Inspect and select the device to configure.',
          InteractionFamily.configure, 'select_device'),
      _phase(
          'Configure network',
          'Record interface and network configuration values.',
          InteractionFamily.configure,
          'configure_network',
          presentation: const {'component': 'configuration'}),
      _phase('Test connectivity', 'Run the initial connectivity test.',
          InteractionFamily.testRun, 'test_connectivity'),
      _phase('Interpret result', 'Interpret the displayed connectivity output.',
          InteractionFamily.decide, 'interpret_result',
          presentation: const {'component': 'result_interpretation'}),
      _phase(
          'Correct and retest',
          'Record a supported configuration correction and repeat the test.',
          InteractionFamily.configure,
          'correct_and_retest'),
      _phase(
          'Review evidence',
          'Review device, configuration, test, and correction evidence.',
          InteractionFamily.review,
          'review_evidence'),
    ],
  ),
  _mission(
    id: 'coc2_m5',
    title: 'Troubleshoot Network Connectivity',
    scenario: 'A workstation cannot reach a service across the local topology.',
    environmentLabel: 'Network diagnostic console',
    practiceGuidance:
        'Inspect topology and configuration facts progressively before making a change.',
    objects: const {
      'workstation': 'Workstation',
      'switch': 'Switch',
      'router': 'Router',
      'server': 'Service host',
    },
    phases: [
      _phase(
          'Inspect topology and configuration',
          'Inspect visible topology and recorded interface values.',
          InteractionFamily.troubleshoot,
          'inspect_topology_and_config'),
      _phase('Test connection', 'Run the initial end-to-end connectivity test.',
          InteractionFamily.testRun, 'test_connection'),
      _phase(
        'Troubleshoot progressively',
        'Reveal one network fact with each diagnostic action.',
        InteractionFamily.troubleshoot,
        'troubleshoot_progressively',
        presentation: _progressiveDiagnostics(
          symptom: 'The workstation cannot reach the service host.',
          actions: const [
            ('inspect_link_state', 'Inspect link state', 'link_state_fact'),
            (
              'inspect_interface_config',
              'Inspect interface configuration',
              'interface_config_fact'
            ),
            ('run_route_probe', 'Run route probe', 'route_probe_fact'),
          ],
          correctionId: 'apply_network_fix',
          correctionLabel: 'Apply the supported network correction',
          retestId: 'retest_network_path',
        ),
      ),
      _phase(
          'Fix and retest',
          'Apply the fact-supported correction and repeat connectivity testing.',
          InteractionFamily.decide,
          'fix_and_retest'),
      _phase(
          'Review evidence',
          'Review topology, diagnostics, correction, and retest evidence.',
          InteractionFamily.review,
          'review_evidence'),
    ],
  ),
];
