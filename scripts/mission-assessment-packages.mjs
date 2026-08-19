export const option = (id, label) => ({ id, label });

const binaryRule = {
  status: "APPROVED",
  method: "binary",
  satisfied_value: 1,
  not_satisfied_value: 0,
  classification: "TECHNICAL_BINARY_ENCODING",
  note: "1/0 encodes SATISFIED/NOT SATISFIED only; it is not a TESDA percentage or criterion weight.",
};

export function selection({ code, title, instruction, actionType, options, expected, source }) {
  return {
    stage: {
      id: code.toLowerCase(),
      criterion_code: code,
      type: "selection",
      title,
      instruction,
      action_type: actionType,
      required_count: expected.length,
      options,
    },
    criterion: {
      criterion_code: code,
      title,
      description: instruction,
      source_trace: source,
      evidence_rule: {
        operator: "final_action_value_set_equals",
        action_type: actionType,
        value_key: "selected_items",
        expected,
      },
    },
  };
}

export function sequence({ code, title, instruction, actionType, steps, source }) {
  const visibleSteps = steps.length > 2 ? [...steps.slice(2), ...steps.slice(0, 2)] : [...steps].reverse();
  return {
    stage: {
      id: code.toLowerCase(),
      criterion_code: code,
      type: "sequence",
      title,
      instruction,
      action_type: actionType,
      options: visibleSteps,
      required_count: steps.length,
    },
    criterion: {
      criterion_code: code,
      title,
      description: instruction,
      source_trace: source,
      evidence_rule: {
        operator: "exact_target_sequence",
        action_type: actionType,
        expected_targets: steps.map((step) => step.id),
      },
    },
  };
}

export function single({ code, title, instruction, actionType, options, expected, source }) {
  return {
    stage: {
      id: code.toLowerCase(),
      criterion_code: code,
      type: "single_choice",
      title,
      instruction,
      action_type: actionType,
      options,
      required_count: 1,
    },
    criterion: {
      criterion_code: code,
      title,
      description: instruction,
      source_trace: source,
      evidence_rule: {
        operator: "final_action_value_equals",
        action_type: actionType,
        value_key: "selected_option",
        expected,
      },
    },
  };
}

export function fields({ code, title, instruction, actionType, fields: fieldDefinitions, source, type = "configuration" }) {
  return {
    stage: {
      id: code.toLowerCase(),
      criterion_code: code,
      type,
      title,
      instruction,
      action_type: actionType,
      fields: fieldDefinitions.map(({ id, label, options }) => ({ id, label, options })),
      required_count: fieldDefinitions.length,
    },
    criterion: {
      criterion_code: code,
      title,
      description: instruction,
      source_trace: source,
      evidence_rule: {
        operator: "final_action_value_set_equals",
        action_type: actionType,
        value_key: "selected_items",
        expected: fieldDefinitions.map(({ id, expected }) => `${id}=${expected}`),
      },
    },
  };
}

export const official = (unit, pcs, operational) =>
  `TESDA_OFFICIAL_APPROVED basis - ${unit} ${pcs}, amended December 2013 CSS NC II Training Regulations and applicable official SAG. ${operational} is PROJECT_APPROVED_OPERATIONAL_RULE for this controlled ByteQuest simulation.`;

const sourceByCoc = {
  coc1: { unitCode: "ELC724331", unitTitle: "Install and Configure Computer Systems", pages: "38-41" },
  coc2: { unitCode: "ELC724332", unitTitle: "Set-up Computer Networks", pages: "42-45" },
  coc3: { unitCode: "ELC724333", unitTitle: "Set-up Computer Servers", pages: "46-48" },
  coc4: { unitCode: "ELC724334", unitTitle: "Maintain and Repair Computer Systems and Networks", pages: "49-53" },
};

export const ppeOptions = [
  option("working_clothes", "Appropriate working clothes"),
  option("safety_glasses", "Safety glasses"),
  option("anti_static_strap", "Anti-static wrist strap"),
  option("loose_jewelry", "Loose jewelry"),
  option("personal_earphones", "Personal earphones"),
];

export const cleanupOptions = [
  option("tools_returned", "Return tools and test devices"),
  option("work_area_cleared", "Leave the work area clean and safe"),
  option("waste_sorted", "Sort excess material under 3Rs/WEEE guidance"),
  option("leave_scraps", "Leave scraps at the workstation"),
  option("leave_power_on", "Leave equipment powered on"),
];

export function packageDefinition({ missionCode, cocCode, title, description, criteria }) {
  const source = sourceByCoc[cocCode];
  return {
    packageId: `${missionCode.replace("_", "-")}-authoritative-v1`,
    missionCode,
    localMissionCode: missionCode.toUpperCase().replace("_", "-"),
    cocCode,
    unitCode: source.unitCode,
    unitTitle: source.unitTitle,
    trPagesPrinted: source.pages,
    title,
    description,
    criteria,
  };
}

export const remainingMissionPackages = [
  packageDefinition({
    missionCode: "coc2_m1", cocCode: "coc2", title: "Plan Network Installation Resources",
    description: "Interpret a controlled site brief, plan the cable route, and prepare compliant materials, tools, test devices, and PPE.",
    criteria: [
      sequence({ code: "COC2-M1-01-ROUTE-PLAN", title: "Cable route planned from the design", instruction: "Arrange the planning actions in the order used to turn the site brief into a checked route plan.", actionType: "coc2_m1_route_step", steps: [option("review_site", "Review the site and network design"), option("mark_endpoints", "Mark required terminal endpoints"), option("choose_safe_route", "Choose a safe cable/raceway route"), option("confirm_design", "Confirm the route against the design")], source: official("ELC724332", "Element 1 PC1.1", "The four-step route-planning evidence contract") }),
      selection({ code: "COC2-M1-02-MATERIALS", title: "Network materials matched to requirements", instruction: "Select the materials required by the controlled wired-LAN installation brief.", actionType: "coc2_m1_materials_submitted", options: [option("cat6_cable", "Cat6 UTP cable"), option("rj45_connectors", "RJ45 connectors"), option("raceway", "Cable raceway"), option("cable_labels", "Cable labels"), option("speaker_wire", "Speaker wire"), option("hdmi_adapter", "HDMI adapter")], expected: ["cat6_cable", "rj45_connectors", "raceway", "cable_labels"], source: official("ELC724332", "Element 1 PC1.2", "The scenario bill of materials") }),
      selection({ code: "COC2-M1-03-TOOLS", title: "Tools and test devices prepared", instruction: "Select the safe tools and test devices required for the installation.", actionType: "coc2_m1_tools_submitted", options: [option("wire_stripper", "Wire stripper"), option("crimping_tool", "Crimping tool"), option("punchdown_tool", "Punch-down tool"), option("lan_tester", "LAN cable tester"), option("paint_brush", "Paint brush"), option("stapler", "Office stapler")], expected: ["wire_stripper", "crimping_tool", "punchdown_tool", "lan_tester"], source: official("ELC724332", "Element 1 PC1.3", "The scenario tool/test-device inventory") }),
      selection({ code: "COC2-M1-04-PPE-OHS", title: "PPE and OHS preparation completed", instruction: "Select the required protective preparation before installation.", actionType: "coc2_m1_ppe_submitted", options: ppeOptions, expected: ["working_clothes", "safety_glasses", "anti_static_strap"], source: official("ELC724332", "Element 1 PC1.4", "The simulated PPE checklist") }),
    ],
  }),
  packageDefinition({
    missionCode: "coc2_m3", cocCode: "coc2", title: "Diagnose Cable Connectivity with a LAN Tester",
    description: "Inspect, test, diagnose, correct, and retest a controlled cable fault without treating final selections as a substitute for chronology.",
    criteria: [
      selection({ code: "COC2-M3-01-SAFE-SETUP", title: "Tester and cable checked before use", instruction: "Select the safe pre-test checks.", actionType: "coc2_m3_pretest_submitted", options: [option("inspect_cable", "Inspect cable and connectors for damage"), option("inspect_tester", "Check tester condition and battery"), option("power_off_before_connect", "Keep tester off while connecting"), option("bend_cable_sharply", "Bend the cable sharply"), option("use_damaged_port", "Use a damaged tester port")], expected: ["inspect_cable", "inspect_tester", "power_off_before_connect"], source: official("ELC724332", "Element 1 PCs1.3, 1.7 and Element 4 PC4.2", "The safe pre-test checklist") }),
      sequence({ code: "COC2-M3-02-TEST-SEQUENCE", title: "LAN tester operated chronologically", instruction: "Arrange the tester actions in the performed order.", actionType: "coc2_m3_tester_step", steps: [option("connect_both_ends", "Connect both cable ends"), option("power_on", "Power on the tester"), option("observe_wire_map", "Observe the 1–8 wire map")], source: official("ELC724332", "Element 2 PC2.1 and Element 4 PC4.2", "The tester-operation sequence") }),
      single({ code: "COC2-M3-03-FAULT-OBSERVATION", title: "Wire-map fault correctly observed", instruction: "Record the fault shown by the controlled tester display.", actionType: "coc2_m3_fault_submitted", options: [option("open_pin_4", "Open circuit at pin 4"), option("short_1_2", "Short between pins 1 and 2"), option("reversed_pair", "Reversed pair"), option("pass", "All pins pass")], expected: "open_pin_4", source: official("ELC724332", "Element 2 PCs2.1–2.2", "The controlled open-pin tester scenario") }),
      sequence({ code: "COC2-M3-04-CORRECT-RETEST", title: "Fault corrected and cable retested", instruction: "Arrange the safe corrective actions and retest in order.", actionType: "coc2_m3_correction_step", steps: [option("power_off", "Power off and disconnect the tester"), option("reterminate_pin4", "Correct the pin-4 termination"), option("reconnect", "Reconnect both ends"), option("retest", "Power on and retest")], source: official("ELC724332", "Element 2 PC2.2 and Element 4 PCs4.1–4.2", "The controlled correction/retest sequence") }),
      single({ code: "COC2-M3-05-FINAL-RESULT", title: "Passing retest result confirmed", instruction: "Record the final tester observation after correction.", actionType: "coc2_m3_retest_result", options: [option("pass_1_to_8", "Pins 1–8 illuminate in order"), option("open_pin_4", "Pin 4 remains open"), option("no_power", "Tester has no power")], expected: "pass_1_to_8", source: official("ELC724332", "Element 4 PCs4.1–4.2", "The controlled passing retest observation") }),
    ],
  }),
  packageDefinition({
    missionCode: "coc2_m4", cocCode: "coc2", title: "Install LAN Devices and Cable Route",
    description: "Follow a controlled design to route cable, connect terminal equipment through the correct ports, inspect the installation, and complete 5S.",
    criteria: [
      selection({ code: "COC2-M4-01-PREPARATION", title: "Installation safety and materials prepared", instruction: "Select the required PPE and installation materials.", actionType: "coc2_m4_preparation_submitted", options: [option("working_clothes", "Appropriate working clothes"), option("safety_glasses", "Safety glasses"), option("cat6_cable", "Cat6 UTP cable"), option("raceway", "Cable raceway"), option("cable_labels", "Cable labels"), option("loose_jewelry", "Loose jewelry")], expected: ["working_clothes", "safety_glasses", "cat6_cable", "raceway", "cable_labels"], source: official("ELC724332", "Element 1 PCs1.2, 1.4 and 1.6", "The controlled installation preparation set") }),
      sequence({ code: "COC2-M4-02-ROUTE", title: "Cable and raceway installed to the design", instruction: "Arrange the physical installation actions in order.", actionType: "coc2_m4_route_step", steps: [option("mark_route", "Mark the approved route"), option("install_raceway", "Install and secure raceway"), option("pull_cable", "Pull cable without excessive bend"), option("label_ends", "Label both cable ends")], source: official("ELC724332", "Element 1 PCs1.1 and 1.6", "The controlled route-installation sequence") }),
      fields({ code: "COC2-M4-03-TOPOLOGY", title: "Devices connected to the correct ports", instruction: "Match each device/link to the correct destination in the approved topology.", actionType: "coc2_m4_topology_submitted", type: "matching", fields: [
        { id: "computer", label: "Computer uplink", options: [option("switch_access", "Switch access port"), option("modem_wan", "Modem WAN port"), option("router_console", "Router console port")], expected: "switch_access" },
        { id: "switch", label: "Switch uplink", options: [option("router_lan", "Router LAN port"), option("computer_usb", "Computer USB port"), option("modem_phone", "Modem phone port")], expected: "router_lan" },
        { id: "router", label: "Router WAN link", options: [option("modem_lan", "Modem LAN port"), option("switch_console", "Switch console port"), option("computer_audio", "Computer audio port")], expected: "modem_lan" },
      ], source: official("ELC724332", "Element 1 PC1.6 and Element 2 PC2.1", "The controlled topology/port mapping") }),
      selection({ code: "COC2-M4-04-INSPECTION-CLEANUP", title: "Installation inspected and work area completed", instruction: "Select the required final inspection and 5S actions.", actionType: "coc2_m4_completion_submitted", options: [option("route_secure", "Raceway and cable are secure"), option("labels_match", "Endpoint labels match the design"), option("no_damage", "No visible cable/port damage"), option("tools_returned", "Tools are returned"), option("waste_sorted", "Excess material is sorted"), option("ignore_damage", "Ignore minor connector damage")], expected: ["route_secure", "labels_match", "no_damage", "tools_returned", "waste_sorted"], source: official("ELC724332", "Element 1 PCs1.7–1.9 and Element 4 PCs4.1–4.2", "The final inspection/5S checklist") }),
    ],
  }),
  packageDefinition({
    missionCode: "coc2_m5", cocCode: "coc2", title: "Configure and Verify a Small LAN",
    description: "Apply a versioned network design to client/router settings, verify terminal communication, and record the final inspection report.",
    criteria: [
      selection({ code: "COC2-M5-01-DESIGN", title: "Network design requirements interpreted", instruction: "Select the settings required by the ByteQuest Lab-A design brief.", actionType: "coc2_m5_design_submitted", options: [option("network_192_168_10_0_24", "LAN 192.168.10.0/24"), option("gateway_192_168_10_1", "Gateway 192.168.10.1"), option("dhcp_100_150", "DHCP pool .100–.150"), option("wpa2_aes", "WPA2-AES wireless security"), option("open_wifi", "Open wireless network"), option("network_10_0_0_0_8", "LAN 10.0.0.0/8")], expected: ["network_192_168_10_0_24", "gateway_192_168_10_1", "dhcp_100_150", "wpa2_aes"], source: official("ELC724332", "Elements 2–3 PCs2.1–2.4 and 3.1–3.5", "The Lab-A network design values") }),
      fields({ code: "COC2-M5-02-CLIENT-NIC", title: "Client NIC configured to the design", instruction: "Choose the required value for each client NIC field.", actionType: "coc2_m5_client_config_submitted", fields: [
        { id: "ip", label: "IPv4 address", options: [option("192.168.10.20", "192.168.10.20"), option("192.168.20.20", "192.168.20.20"), option("169.254.10.20", "169.254.10.20")], expected: "192.168.10.20" },
        { id: "mask", label: "Subnet mask", options: [option("255.255.255.0", "255.255.255.0"), option("255.0.0.0", "255.0.0.0")], expected: "255.255.255.0" },
        { id: "gateway", label: "Default gateway", options: [option("192.168.10.1", "192.168.10.1"), option("192.168.10.254", "192.168.10.254")], expected: "192.168.10.1" },
        { id: "dns", label: "DNS server", options: [option("192.168.10.1", "192.168.10.1"), option("192.168.20.1", "192.168.20.1")], expected: "192.168.10.1" },
      ], source: official("ELC724332", "Element 2 PC2.3 and Element 3 PC3.1", "The Lab-A client NIC values") }),
      fields({ code: "COC2-M5-03-ROUTER", title: "Router LAN and security settings configured", instruction: "Choose the required router settings from the approved design.", actionType: "coc2_m5_router_config_submitted", fields: [
        { id: "lan_ip", label: "Router LAN address", options: [option("192.168.10.1", "192.168.10.1"), option("192.168.10.20", "192.168.10.20")], expected: "192.168.10.1" },
        { id: "dhcp", label: "DHCP scope", options: [option("192.168.10.100-150", ".100–.150"), option("192.168.20.100-150", "192.168.20 .100–.150")], expected: "192.168.10.100-150" },
        { id: "wireless_security", label: "Wireless security", options: [option("wpa2_aes", "WPA2-AES"), option("open", "Open"), option("wep", "WEP")], expected: "wpa2_aes" },
        { id: "firewall", label: "Firewall", options: [option("enabled", "Enabled"), option("disabled", "Disabled")], expected: "enabled" },
      ], source: official("ELC724332", "Element 3 PCs3.2–3.5", "The Lab-A router/security configuration") }),
      sequence({ code: "COC2-M5-04-COMMUNICATION", title: "Terminal communication verified", instruction: "Arrange the connectivity checks in diagnostic order.", actionType: "coc2_m5_connectivity_step", steps: [option("verify_link", "Verify physical link state"), option("check_ipconfig", "Review client IP configuration"), option("ping_gateway", "Ping the default gateway"), option("ping_peer", "Ping the peer terminal")], source: official("ELC724332", "Element 2 PCs2.1, 2.4 and Element 4 PC4.2", "The Lab-A communication-check sequence") }),
      selection({ code: "COC2-M5-05-REPORT", title: "Configuration inspection report completed", instruction: "Select the observations that belong in the final controlled report.", actionType: "coc2_m5_report_submitted", options: [option("design_values_match", "Configured values match Lab-A design"), option("gateway_reachable", "Gateway is reachable"), option("peer_reachable", "Peer terminal is reachable"), option("firewall_enabled", "Firewall remains enabled"), option("unresolved_fault", "An unresolved fault remains")], expected: ["design_values_match", "gateway_reachable", "peer_reachable", "firewall_enabled"], source: official("ELC724332", "Element 4 PCs4.1–4.3", "The structured final inspection report") }),
    ],
  }),
];

export function buildLearnerPayload(definition) {
  return {
    assessment_package_id: definition.packageId,
    local_mission_code: definition.localMissionCode,
    simulation_template: "authoritative_mission_v1",
    result_visibility: "released_only",
    supplementary_disclaimer: true,
    unit_code: definition.unitCode,
    unit_title: definition.unitTitle,
    stages: definition.criteria.map(({ stage }) => stage),
  };
}

export function buildRubricCriteria(definition) {
  return definition.criteria.map(({ criterion }, index) => ({
    ...criterion,
    scoring_rule: binaryRule,
    max_value: 1,
    order_index: index + 1,
    is_required: true,
  }));
}

export function validateMissionPackages(definitions = remainingMissionPackages) {
  const errors = [];
  const missionCodes = new Set();
  const packageIds = new Set();
  const criterionCodes = new Set();
  for (const definition of definitions) {
    if (missionCodes.has(definition.missionCode)) errors.push(`Duplicate mission ${definition.missionCode}`);
    if (packageIds.has(definition.packageId)) errors.push(`Duplicate package ${definition.packageId}`);
    missionCodes.add(definition.missionCode);
    packageIds.add(definition.packageId);
    if (!sourceByCoc[definition.cocCode]) errors.push(`Unknown COC ${definition.cocCode}`);
    if (!definition.criteria.length) errors.push(`${definition.missionCode} has no criteria`);
    for (const item of definition.criteria) {
      if (criterionCodes.has(item.criterion.criterion_code)) errors.push(`Duplicate criterion ${item.criterion.criterion_code}`);
      criterionCodes.add(item.criterion.criterion_code);
      if (JSON.stringify(item.stage).includes('"expected"')) errors.push(`${item.criterion.criterion_code} leaks an expected answer`);
      if (item.stage.criterion_code !== item.criterion.criterion_code) errors.push(`${item.criterion.criterion_code} stage mismatch`);
    }
  }
  if (errors.length) throw new Error(errors.join("\n"));
  return {
    missions: definitions.length,
    criteria: definitions.reduce((sum, definition) => sum + definition.criteria.length, 0),
    cocs: [...new Set(definitions.map((definition) => definition.cocCode))],
  };
}
