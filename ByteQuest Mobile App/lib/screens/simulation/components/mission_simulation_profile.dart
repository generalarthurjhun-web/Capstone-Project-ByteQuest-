import 'package:flutter/material.dart';

/// The dominant technical activity a learner should feel they are performing.
/// This is presentation metadata only; assessment authority remains in the
/// published activity/rubric versions and PostgreSQL evaluation rules.
enum MissionInteractionIdentity {
  planning,
  inspection,
  assembly,
  connection,
  configuration,
  deployment,
  diagnostics,
  maintenance,
  repair,
  verification,
}

enum SimulationSceneKind {
  workbench,
  openChassis,
  firmwareConsole,
  networkPlan,
  cableTester,
  networkBench,
  serverRack,
  accessConsole,
  maintenanceBay,
}

class SimulationSceneObjectSpec {
  final String id;
  final String label;
  final IconData icon;
  final Offset position;

  const SimulationSceneObjectSpec({
    required this.id,
    required this.label,
    required this.icon,
    required this.position,
  });
}

class MissionSimulationProfile {
  final String missionCode;
  final MissionInteractionIdentity identity;
  final SimulationSceneKind sceneKind;
  final String environmentTitle;
  final String scenarioPrompt;
  final List<SimulationSceneObjectSpec> sceneObjects;

  const MissionSimulationProfile({
    required this.missionCode,
    required this.identity,
    required this.sceneKind,
    required this.environmentTitle,
    required this.scenarioPrompt,
    required this.sceneObjects,
  });

  String get identityLabel => switch (identity) {
        MissionInteractionIdentity.planning => 'Planning workflow',
        MissionInteractionIdentity.inspection => 'Inspection workflow',
        MissionInteractionIdentity.assembly => 'Assembly workflow',
        MissionInteractionIdentity.connection => 'Connection workflow',
        MissionInteractionIdentity.configuration => 'Configuration workflow',
        MissionInteractionIdentity.deployment => 'Deployment workflow',
        MissionInteractionIdentity.diagnostics => 'Diagnostic workflow',
        MissionInteractionIdentity.maintenance => 'Maintenance workflow',
        MissionInteractionIdentity.repair => 'Repair workflow',
        MissionInteractionIdentity.verification => 'Verification workflow',
      };

  static MissionSimulationProfile forMission(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    return _profiles[normalized] ??
        MissionSimulationProfile(
          missionCode: normalized,
          identity: MissionInteractionIdentity.inspection,
          sceneKind: SimulationSceneKind.workbench,
          environmentTitle: 'CSS technical workspace',
          scenarioPrompt:
              'Inspect the simulated work area before recording the required evidence.',
          sceneObjects: _workbenchObjects,
        );
  }
}

const _workbenchObjects = <SimulationSceneObjectSpec>[
  SimulationSceneObjectSpec(
    id: 'work_order',
    label: 'Work order',
    icon: Icons.description_outlined,
    position: Offset(.18, .28),
  ),
  SimulationSceneObjectSpec(
    id: 'equipment',
    label: 'Equipment',
    icon: Icons.computer_outlined,
    position: Offset(.50, .52),
  ),
  SimulationSceneObjectSpec(
    id: 'tool_area',
    label: 'Tool area',
    icon: Icons.handyman_outlined,
    position: Offset(.82, .30),
  ),
];

const _chassisObjects = <SimulationSceneObjectSpec>[
  SimulationSceneObjectSpec(
    id: 'motherboard',
    label: 'Mainboard',
    icon: Icons.developer_board_outlined,
    position: Offset(.31, .48),
  ),
  SimulationSceneObjectSpec(
    id: 'power_supply',
    label: 'Power supply',
    icon: Icons.power_outlined,
    position: Offset(.72, .28),
  ),
  SimulationSceneObjectSpec(
    id: 'drive_bay',
    label: 'Drive bay',
    icon: Icons.storage_outlined,
    position: Offset(.74, .66),
  ),
];

const _networkObjects = <SimulationSceneObjectSpec>[
  SimulationSceneObjectSpec(
    id: 'client',
    label: 'Client',
    icon: Icons.computer_outlined,
    position: Offset(.18, .62),
  ),
  SimulationSceneObjectSpec(
    id: 'switch',
    label: 'Switch',
    icon: Icons.hub_outlined,
    position: Offset(.50, .42),
  ),
  SimulationSceneObjectSpec(
    id: 'router',
    label: 'Router',
    icon: Icons.router_outlined,
    position: Offset(.82, .24),
  ),
];

const _serverObjects = <SimulationSceneObjectSpec>[
  SimulationSceneObjectSpec(
    id: 'server',
    label: 'Server',
    icon: Icons.dns_outlined,
    position: Offset(.50, .42),
  ),
  SimulationSceneObjectSpec(
    id: 'service_console',
    label: 'Services',
    icon: Icons.settings_ethernet_outlined,
    position: Offset(.20, .64),
  ),
  SimulationSceneObjectSpec(
    id: 'client_access',
    label: 'Client access',
    icon: Icons.laptop_chromebook_outlined,
    position: Offset(.80, .64),
  ),
];

const _profiles = <String, MissionSimulationProfile>{
  'coc1_m1': MissionSimulationProfile(
    missionCode: 'coc1_m1',
    identity: MissionInteractionIdentity.planning,
    sceneKind: SimulationSceneKind.workbench,
    environmentTitle: 'Desktop assembly workbench',
    scenarioPrompt:
        'Inspect the work order, equipment area, and service tools before planning the build.',
    sceneObjects: _workbenchObjects,
  ),
  'coc1_m2': MissionSimulationProfile(
    missionCode: 'coc1_m2',
    identity: MissionInteractionIdentity.assembly,
    sceneKind: SimulationSceneKind.openChassis,
    environmentTitle: 'Open desktop chassis',
    scenarioPrompt:
        'Inspect the component locations and installation clearances before assembly.',
    sceneObjects: _chassisObjects,
  ),
  'coc1_m3': MissionSimulationProfile(
    missionCode: 'coc1_m3',
    identity: MissionInteractionIdentity.connection,
    sceneKind: SimulationSceneKind.openChassis,
    environmentTitle: 'Power and data connection bay',
    scenarioPrompt:
        'Inspect keyed connectors, cable paths, and device ports before making connections.',
    sceneObjects: _chassisObjects,
  ),
  'coc1_m4': MissionSimulationProfile(
    missionCode: 'coc1_m4',
    identity: MissionInteractionIdentity.deployment,
    sceneKind: SimulationSceneKind.firmwareConsole,
    environmentTitle: 'Firmware and OS deployment console',
    scenarioPrompt:
        'Review detected hardware, boot media, and firmware state before deployment.',
    sceneObjects: <SimulationSceneObjectSpec>[
      SimulationSceneObjectSpec(
          id: 'firmware',
          label: 'Firmware',
          icon: Icons.memory_outlined,
          position: Offset(.20, .34)),
      SimulationSceneObjectSpec(
          id: 'boot_media',
          label: 'Boot media',
          icon: Icons.usb_outlined,
          position: Offset(.50, .64)),
      SimulationSceneObjectSpec(
          id: 'installer',
          label: 'Installer',
          icon: Icons.install_desktop_outlined,
          position: Offset(.80, .34)),
    ],
  ),
  'coc1_m5': MissionSimulationProfile(
    missionCode: 'coc1_m5',
    identity: MissionInteractionIdentity.verification,
    sceneKind: SimulationSceneKind.firmwareConsole,
    environmentTitle: 'Post-installation verification station',
    scenarioPrompt:
        'Inspect device state, approved packages, and quality checks before reporting completion.',
    sceneObjects: <SimulationSceneObjectSpec>[
      SimulationSceneObjectSpec(
          id: 'drivers',
          label: 'Drivers',
          icon: Icons.extension_outlined,
          position: Offset(.20, .34)),
      SimulationSceneObjectSpec(
          id: 'updates',
          label: 'Updates',
          icon: Icons.system_update_alt_outlined,
          position: Offset(.50, .64)),
      SimulationSceneObjectSpec(
          id: 'health',
          label: 'System health',
          icon: Icons.monitor_heart_outlined,
          position: Offset(.80, .34)),
    ],
  ),
  'coc2_m1': MissionSimulationProfile(
    missionCode: 'coc2_m1',
    identity: MissionInteractionIdentity.planning,
    sceneKind: SimulationSceneKind.networkPlan,
    environmentTitle: 'Network installation plan',
    scenarioPrompt:
        'Inspect endpoints, route constraints, and the installation inventory before planning.',
    sceneObjects: _networkObjects,
  ),
  'coc2_m2': MissionSimulationProfile(
    missionCode: 'coc2_m2',
    identity: MissionInteractionIdentity.connection,
    sceneKind: SimulationSceneKind.cableTester,
    environmentTitle: 'Cable termination and testing bench',
    scenarioPrompt:
        'Prepare, terminate, inspect, and verify the controlled cable using ordered evidence.',
    sceneObjects: _networkObjects,
  ),
  'coc2_m3': MissionSimulationProfile(
    missionCode: 'coc2_m3',
    identity: MissionInteractionIdentity.diagnostics,
    sceneKind: SimulationSceneKind.cableTester,
    environmentTitle: 'LAN cable diagnostic bench',
    scenarioPrompt:
        'Inspect the cable and tester, perform the test, isolate the fault, and verify the repair.',
    sceneObjects: <SimulationSceneObjectSpec>[
      SimulationSceneObjectSpec(
          id: 'main_tester',
          label: 'Main tester',
          icon: Icons.electrical_services_outlined,
          position: Offset(.22, .42)),
      SimulationSceneObjectSpec(
          id: 'cable_under_test',
          label: 'Test cable',
          icon: Icons.cable_outlined,
          position: Offset(.50, .65)),
      SimulationSceneObjectSpec(
          id: 'remote_unit',
          label: 'Remote unit',
          icon: Icons.sensors_outlined,
          position: Offset(.78, .42)),
    ],
  ),
  'coc2_m4': MissionSimulationProfile(
    missionCode: 'coc2_m4',
    identity: MissionInteractionIdentity.connection,
    sceneKind: SimulationSceneKind.networkBench,
    environmentTitle: 'LAN installation topology',
    scenarioPrompt:
        'Inspect the approved route, endpoint labels, and device ports before installation.',
    sceneObjects: _networkObjects,
  ),
  'coc2_m5': MissionSimulationProfile(
    missionCode: 'coc2_m5',
    identity: MissionInteractionIdentity.configuration,
    sceneKind: SimulationSceneKind.networkBench,
    environmentTitle: 'Small LAN configuration console',
    scenarioPrompt:
        'Review the design and live device state before configuring and testing communication.',
    sceneObjects: _networkObjects,
  ),
  'coc3_m1': MissionSimulationProfile(
    missionCode: 'coc3_m1',
    identity: MissionInteractionIdentity.planning,
    sceneKind: SimulationSceneKind.serverRack,
    environmentTitle: 'Server deployment planning bay',
    scenarioPrompt:
        'Inspect the server platform, required services, and client needs before implementation.',
    sceneObjects: _serverObjects,
  ),
  'coc3_m2': MissionSimulationProfile(
    missionCode: 'coc3_m2',
    identity: MissionInteractionIdentity.deployment,
    sceneKind: SimulationSceneKind.serverRack,
    environmentTitle: 'Network operating system console',
    scenarioPrompt:
        'Inspect server readiness, installation media, and required roles before deployment.',
    sceneObjects: _serverObjects,
  ),
  'coc3_m3': MissionSimulationProfile(
    missionCode: 'coc3_m3',
    identity: MissionInteractionIdentity.configuration,
    sceneKind: SimulationSceneKind.serverRack,
    environmentTitle: 'Server network configuration bay',
    scenarioPrompt:
        'Inspect the server NIC, service bindings, and client path before applying the network plan.',
    sceneObjects: _serverObjects,
  ),
  'coc3_m4': MissionSimulationProfile(
    missionCode: 'coc3_m4',
    identity: MissionInteractionIdentity.configuration,
    sceneKind: SimulationSceneKind.accessConsole,
    environmentTitle: 'User and permission console',
    scenarioPrompt:
        'Inspect users, groups, shared resources, and access policy before assigning permissions.',
    sceneObjects: <SimulationSceneObjectSpec>[
      SimulationSceneObjectSpec(
          id: 'users',
          label: 'Users',
          icon: Icons.person_outline_rounded,
          position: Offset(.20, .38)),
      SimulationSceneObjectSpec(
          id: 'groups',
          label: 'Groups',
          icon: Icons.group_outlined,
          position: Offset(.50, .62)),
      SimulationSceneObjectSpec(
          id: 'shared_folder',
          label: 'Shared folder',
          icon: Icons.folder_shared_outlined,
          position: Offset(.80, .38)),
    ],
  ),
  'coc3_m5': MissionSimulationProfile(
    missionCode: 'coc3_m5',
    identity: MissionInteractionIdentity.diagnostics,
    sceneKind: SimulationSceneKind.serverRack,
    environmentTitle: 'Server service verification bay',
    scenarioPrompt:
        'Observe service and client symptoms, diagnose the interruption, restore service, and retest.',
    sceneObjects: _serverObjects,
  ),
  'coc4_m1': MissionSimulationProfile(
    missionCode: 'coc4_m1',
    identity: MissionInteractionIdentity.diagnostics,
    sceneKind: SimulationSceneKind.maintenanceBay,
    environmentTitle: 'Computer fault isolation bay',
    scenarioPrompt:
        'Inspect the service order, baseline condition, and test resources before isolating the fault.',
    sceneObjects: _workbenchObjects,
  ),
  'coc4_m2': MissionSimulationProfile(
    missionCode: 'coc4_m2',
    identity: MissionInteractionIdentity.maintenance,
    sceneKind: SimulationSceneKind.maintenanceBay,
    environmentTitle: 'Preventive maintenance workstation',
    scenarioPrompt:
        'Inspect power state, ESD controls, components, and cleaning tools before maintenance.',
    sceneObjects: _chassisObjects,
  ),
  'coc4_m3': MissionSimulationProfile(
    missionCode: 'coc4_m3',
    identity: MissionInteractionIdentity.diagnostics,
    sceneKind: SimulationSceneKind.openChassis,
    environmentTitle: 'Intermittent hardware diagnostic bay',
    scenarioPrompt:
        'Observe the memory-related symptom, choose tests, isolate the fault, correct it, and retest.',
    sceneObjects: _chassisObjects,
  ),
  'coc4_m4': MissionSimulationProfile(
    missionCode: 'coc4_m4',
    identity: MissionInteractionIdentity.diagnostics,
    sceneKind: SimulationSceneKind.networkBench,
    environmentTitle: 'LAN connectivity diagnostic topology',
    scenarioPrompt:
        'Inspect the client, switch path, and VLAN-port state before testing and correction.',
    sceneObjects: _networkObjects,
  ),
  'coc4_m5': MissionSimulationProfile(
    missionCode: 'coc4_m5',
    identity: MissionInteractionIdentity.repair,
    sceneKind: SimulationSceneKind.maintenanceBay,
    environmentTitle: 'Storage repair and verification bay',
    scenarioPrompt:
        'Inspect the failed drive, replacement path, collateral condition, and final test state.',
    sceneObjects: _chassisObjects,
  ),
};
