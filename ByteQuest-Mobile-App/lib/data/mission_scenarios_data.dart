import '../models/mission_scenario_model.dart';

/// Complete Mission Scenarios Data for all COCs
/// Contains detailed scenario-based mission information
class MissionScenariosData {
  /// Get all mission scenarios
  static List<MissionScenario> getAllScenarios() {
    return [
      ...getCOC1Scenarios(),
      ...getCOC2Scenarios(),
      ...getCOC3Scenarios(),
      ...getCOC4Scenarios(),
    ];
  }

  /// Get scenario by mission ID
  static MissionScenario? getScenarioByMissionId(String missionId) {
    try {
      return getAllScenarios().firstWhere((s) => s.missionId == missionId);
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // COC 1: PC Builder Quest Scenarios
  // ==========================================
  static List<MissionScenario> getCOC1Scenarios() {
    return [
      MissionScenario(
        missionId: 'coc1_m1',
        cocId: 'coc1',
        missionNumber: 1,
        missionTitle: 'Identify Computer Parts and Tools',
        moduleName: 'PC Builder Quest',
        scenario:
            'You are hired as a junior technician in a computer repair shop. Your supervisor asks you to organize the parts and tools inventory. To complete this task, you must correctly identify all computer components and tools used in PC assembly and maintenance.',
        objective:
            'Correctly identify 10 computer parts, peripherals, and tools by selecting the matching images.',
        skillsAssessed: [
          'Hardware component recognition',
          'Tool identification',
          'Visual analysis and matching',
          'Technical vocabulary knowledge',
        ],
        challengeDescription:
            'Complete the practice identification and review the local feedback. Hints are available in practice mode only.',
        difficulty: 'Easy',
        xpReward: 0,
        estimatedTime: 10,
        passingScore: 0,
      ),
      MissionScenario(
        missionId: 'coc1_m2',
        cocId: 'coc1',
        missionNumber: 2,
        missionTitle: 'Install Internal Components',
        moduleName: 'PC Builder Quest',
        scenario:
            'A newly delivered computer unit must be assembled before it can be used in a computer laboratory. As the assigned technician, you must install the internal components properly inside the system unit case.',
        objective:
            'Install the motherboard, CPU, RAM, storage device, cooling fan/heatsink, and PSU into their correct locations inside the computer case.',
        skillsAssessed: [
          'Component installation procedures',
          'Proper handling of sensitive parts',
          'Correct placement and orientation',
          'Task sequencing and completion',
        ],
        challengeDescription:
            'Complete the practice installation and review the local placement feedback.',
        difficulty: 'Medium',
        xpReward: 0,
        estimatedTime: 20,
        passingScore: 0,
      ),
      MissionScenario(
        missionId: 'coc1_m3',
        cocId: 'coc1',
        missionNumber: 3,
        missionTitle: 'Connect Power and Data Cables',
        moduleName: 'PC Builder Quest',
        scenario:
            'The internal components are now installed. Your next task is to connect all power and data cables to ensure the system receives power and components can communicate with each other.',
        objective:
            'Connect the 24-pin ATX cable, CPU power cable, SATA data cable, SATA power cable, and front panel connectors to their correct ports.',
        skillsAssessed: [
          'Cable identification',
          'Port recognition',
          'Proper cable management',
          'Connection procedures',
        ],
        challengeDescription:
            'Connect all cables correctly with minimal errors. Proper cable management ensures system stability and airflow.',
        difficulty: 'Medium',
        xpReward: 0,
        estimatedTime: 15,
        passingScore: 0,
      ),
      MissionScenario(
        missionId: 'coc1_m4',
        cocId: 'coc1',
        missionNumber: 4,
        missionTitle: 'Configure BIOS/UEFI and Install OS',
        moduleName: 'PC Builder Quest',
        scenario:
            'The hardware is fully assembled. Now you must access the BIOS/UEFI firmware, verify hardware detection, configure boot priority, and guide the operating system installation process.',
        objective:
            'Configure BIOS settings correctly and follow the proper sequence for operating system installation.',
        skillsAssessed: [
          'BIOS/UEFI navigation',
          'Boot configuration',
          'Hardware verification',
          'OS installation procedures',
        ],
        challengeDescription:
            'Configure the system correctly to ensure successful OS installation. Pay attention to boot device priority and hardware detection.',
        difficulty: 'Hard',
        xpReward: 0,
        estimatedTime: 25,
        passingScore: 0,
      ),
      MissionScenario(
        missionId: 'coc1_m5',
        cocId: 'coc1',
        missionNumber: 5,
        missionTitle: 'Install Drivers and Test the System',
        moduleName: 'PC Builder Quest',
        scenario:
            'The operating system is installed, but the computer needs device drivers to function properly. As the final step, you must install all necessary drivers and perform system tests to ensure everything works correctly.',
        objective:
            'Install LAN, audio, graphics, and chipset drivers, then test all hardware components (display, keyboard, mouse, audio, network) to verify functionality.',
        skillsAssessed: [
          'Driver installation procedures',
          'Hardware testing methods',
          'System verification',
          'Troubleshooting basics',
        ],
        challengeDescription:
            'Complete all driver installations and hardware tests in the correct sequence. All tests must pass for mission completion.',
        difficulty: 'Medium',
        xpReward: 0,
        estimatedTime: 20,
        passingScore: 0,
      ),
    ];
  }

  // ==========================================
  // COC 2: Network Builder Quest Scenarios
  // ==========================================
  static List<MissionScenario> getCOC2Scenarios() {
    return [
      MissionScenario(
        missionId: 'coc2_m1',
        cocId: 'coc2',
        missionNumber: 1,
        missionTitle: 'Identify Network Devices and Tools',
        moduleName: 'Network Builder Quest',
        scenario:
            'You are assigned to set up a local area network in a small office. Before starting, you must identify all networking devices, cables, connectors, and tools required for the installation.',
        objective:
            'Correctly identify routers, switches, modems, cables, connectors, and networking tools.',
        skillsAssessed: [
          'Network device recognition',
          'Cable and connector identification',
          'Tool identification',
          'Network terminology',
        ],
        challengeDescription:
            'Identify the network components and review the local practice feedback.',
        difficulty: 'Easy',
        xpReward: 0,
        estimatedTime: 10,
        passingScore: 0,
      ),
      MissionScenario(
        missionId: 'coc2_m2',
        cocId: 'coc2',
        missionNumber: 2,
        missionTitle: 'Create Network Cables',
        moduleName: 'Network Builder Quest',
        scenario:
            'The office needs custom-length network cables. You must create straight-through Ethernet cables by arranging the wires in the correct T568B standard sequence.',
        objective:
            'Arrange the 8 Ethernet cable wires in the correct color sequence following the T568B standard.',
        skillsAssessed: [
          'T568B wiring standard',
          'Cable termination',
          'Wire sequencing',
          'Attention to detail',
        ],
        challengeDescription:
            'Create a properly wired network cable. Incorrect wire sequence will result in cable failure.',
        difficulty: 'Medium',
        xpReward: 0,
        estimatedTime: 15,
        passingScore: 0,
      ),
      MissionScenario(
        missionId: 'coc2_m3',
        cocId: 'coc2',
        missionNumber: 3,
        missionTitle: 'Test Cable Connectivity',
        moduleName: 'Network Builder Quest',
        scenario:
            'After creating the network cables, you must verify their functionality using a LAN cable tester before installation.',
        objective:
            'Use the LAN cable tester to verify cable connectivity and identify any wiring faults.',
        skillsAssessed: [
          'Cable testing procedures',
          'Result interpretation',
          'Quality assurance',
          'Fault identification',
        ],
        challengeDescription:
            'Follow the correct testing procedure and verify all 8 wires are properly connected.',
        difficulty: 'Easy',
        xpReward: 0,
        estimatedTime: 10,
        passingScore: 0,
      ),
      MissionScenario(
        missionId: 'coc2_m4',
        cocId: 'coc2',
        missionNumber: 4,
        missionTitle: 'Connect Devices in a Local Area Network',
        moduleName: 'Network Builder Quest',
        scenario:
            'With working cables ready, you must now physically connect all network devices to create a functional local area network topology.',
        objective:
            'Connect computers to the switch, switch to the router, and router to the modem to establish network connectivity.',
        skillsAssessed: [
          'Network topology understanding',
          'Device interconnection',
          'Physical layer setup',
          'Network architecture',
        ],
        challengeDescription:
            'Connect all devices in the correct sequence to form a working LAN that can access the internet.',
        difficulty: 'Hard',
        xpReward: 0,
        estimatedTime: 20,
        passingScore: 0,
      ),
      MissionScenario(
        missionId: 'coc2_m5',
        cocId: 'coc2',
        missionNumber: 5,
        missionTitle: 'Configure IP Settings and Test Connection',
        moduleName: 'Network Builder Quest',
        scenario:
            'The physical network is set up. Now you must configure the network settings on a client computer and test connectivity to ensure proper communication.',
        objective:
            'Configure IP address, subnet mask, default gateway, and DNS server, then test the network connection.',
        skillsAssessed: [
          'IP configuration',
          'Network parameters understanding',
          'Connectivity testing',
          'Troubleshooting basics',
        ],
        challengeDescription:
            'Enter correct network configuration values and verify successful connectivity to complete the network setup.',
        difficulty: 'Hard',
        xpReward: 0,
        estimatedTime: 20,
        passingScore: 0,
      ),
    ];
  }

  // ==========================================
  // COC 3: Server Setup Quest Scenarios
  // ==========================================
  static List<MissionScenario> getCOC3Scenarios() {
    return [
      MissionScenario(
        missionId: 'coc3_m1',
        cocId: 'coc3',
        missionNumber: 1,
        missionTitle: 'Prepare Server Setup Requirements',
        moduleName: 'Server Setup Quest',
        scenario:
            'Your company needs a file server for centralized data storage and sharing. You must prepare and verify all requirements before beginning the server installation.',
        objective:
            'Identify and confirm all required hardware, software, documentation, and infrastructure for server setup.',
        skillsAssessed: [
          'Server hardware recognition',
          'Requirement analysis',
          'Pre-installation planning',
          'Documentation awareness',
        ],
        challengeDescription:
            'Identify all server setup requirements correctly to ensure smooth installation and deployment.',
        difficulty: 'Medium',
        xpReward: 0,
        estimatedTime: 15,
        passingScore: 0,
      ),
      MissionScenario(
        missionId: 'coc3_m2',
        cocId: 'coc3',
        missionNumber: 2,
        missionTitle: 'Install and Configure Server OS',
        moduleName: 'Server Setup Quest',
        scenario:
            'With hardware ready, you must install the server operating system following proper procedures to ensure a stable and secure server environment.',
        objective:
            'Complete the server OS installation by following all required steps in the correct sequence.',
        skillsAssessed: [
          'OS installation procedures',
          'Server configuration basics',
          'Administrator account setup',
          'System initialization',
        ],
        challengeDescription:
            'Follow each installation step carefully. Incorrect configuration may cause server instability.',
        difficulty: 'Hard',
        xpReward: 0,
        estimatedTime: 25,
        passingScore: 0,
      ),
      MissionScenario(
        missionId: 'coc3_m3',
        cocId: 'coc3',
        missionNumber: 3,
        missionTitle: 'Configure Server Network Settings',
        moduleName: 'Server Setup Quest',
        scenario:
            'The server OS is installed. Now you must configure network settings with a static IP address so the server can be reliably accessed by client computers.',
        objective:
            'Configure static IP address, subnet mask, default gateway, and DNS server for the server.',
        skillsAssessed: [
          'Static IP configuration',
          'Server network setup',
          'Network addressing',
          'DNS configuration',
        ],
        challengeDescription:
            'Enter correct static network settings. Servers require static IPs for reliable client access.',
        difficulty: 'Hard',
        xpReward: 0,
        estimatedTime: 20,
        passingScore: 0,
      ),
      MissionScenario(
        missionId: 'coc3_m4',
        cocId: 'coc3',
        missionNumber: 4,
        missionTitle: 'Create Users, Groups, and Permissions',
        moduleName: 'Server Setup Quest',
        scenario:
            'Multiple employees need access to the server with different permission levels. You must create user accounts, organize them into groups, and assign appropriate permissions to shared folders.',
        objective:
            'Create user accounts, assign them to groups, create shared folders, and configure access permissions.',
        skillsAssessed: [
          'User account management',
          'Group administration',
          'Permission configuration',
          'Security principles',
        ],
        challengeDescription:
            'Configure users and permissions correctly to ensure proper access control and data security.',
        difficulty: 'Hard',
        xpReward: 0,
        estimatedTime: 25,
        passingScore: 0,
      ),
      MissionScenario(
        missionId: 'coc3_m5',
        cocId: 'coc3',
        missionNumber: 5,
        missionTitle: 'Test Client Access and Document Server Setup',
        moduleName: 'Server Setup Quest',
        scenario:
            'The server is configured. You must now verify that client computers can successfully access the server and complete the setup documentation.',
        objective:
            'Test client connectivity, verify file access permissions, and ensure the server setup meets all requirements.',
        skillsAssessed: [
          'Client connectivity testing',
          'Access verification',
          'Troubleshooting',
          'Documentation procedures',
        ],
        challengeDescription:
            'Verify all clients can access the server correctly and troubleshoot any access issues.',
        difficulty: 'Medium',
        xpReward: 0,
        estimatedTime: 20,
        passingScore: 0,
      ),
    ];
  }

  // ==========================================
  // COC 4: Troubleshooting and Repair Quest Scenarios
  // ==========================================
  static List<MissionScenario> getCOC4Scenarios() {
    return [
      MissionScenario(
        missionId: 'coc4_m1',
        cocId: 'coc4',
        missionNumber: 1,
        missionTitle: 'Identify System and Network Problems',
        moduleName: 'Troubleshooting and Repair Quest',
        scenario:
            'Users are reporting various computer and network issues. As a technician, you must correctly identify the root cause of each problem based on the symptoms described.',
        objective:
            'Match each symptom to its correct root cause to demonstrate diagnostic skills.',
        skillsAssessed: [
          'Problem identification',
          'Symptom analysis',
          'Root cause determination',
          'Diagnostic reasoning',
        ],
        challengeDescription:
            'Identify the likely causes and review the local practice feedback.',
        difficulty: 'Medium',
        xpReward: 0,
        estimatedTime: 15,
        passingScore: 0,
      ),
      MissionScenario(
        missionId: 'coc4_m2',
        cocId: 'coc4',
        missionNumber: 2,
        missionTitle: 'Perform Preventive Maintenance',
        moduleName: 'Troubleshooting and Repair Quest',
        scenario:
            'To prevent hardware failures and extend system life, you must perform regular preventive maintenance on a computer system following proper safety procedures.',
        objective:
            'Complete all preventive maintenance steps in the correct sequence, including safety precautions.',
        skillsAssessed: [
          'Preventive maintenance procedures',
          'Safety protocols',
          'Component inspection',
          'Cleaning techniques',
        ],
        challengeDescription:
            'Follow each maintenance step carefully and in the correct order to ensure safety and effectiveness.',
        difficulty: 'Medium',
        xpReward: 0,
        estimatedTime: 20,
        passingScore: 0,
      ),
      MissionScenario(
        missionId: 'coc4_m3',
        cocId: 'coc4',
        missionNumber: 3,
        missionTitle: 'Diagnose Hardware and Software Faults',
        moduleName: 'Troubleshooting and Repair Quest',
        scenario:
            'Several computers are experiencing critical hardware and software failures. You must diagnose the exact fault for each system to determine the appropriate repair action.',
        objective:
            'Identify the correct hardware or software fault causing each system failure.',
        skillsAssessed: [
          'Hardware diagnostics',
          'Software fault analysis',
          'Systematic troubleshooting',
          'Decision-making skills',
        ],
        challengeDescription:
            'Diagnose each fault correctly using logical troubleshooting methods.',
        difficulty: 'Hard',
        xpReward: 0,
        estimatedTime: 25,
        passingScore: 0,
      ),
      MissionScenario(
        missionId: 'coc4_m4',
        cocId: 'coc4',
        missionNumber: 4,
        missionTitle: 'Troubleshoot Network Issues',
        moduleName: 'Troubleshooting and Repair Quest',
        scenario:
            'Multiple users are experiencing network connectivity problems. You must systematically troubleshoot and identify the cause of each network issue.',
        objective:
            'Troubleshoot network problems and identify the correct root cause for each connectivity issue.',
        skillsAssessed: [
          'Network troubleshooting',
          'Connectivity diagnosis',
          'Systematic problem-solving',
          'Network fault identification',
        ],
        challengeDescription:
            'Use systematic troubleshooting steps to identify each network problem correctly.',
        difficulty: 'Hard',
        xpReward: 0,
        estimatedTime: 20,
        passingScore: 0,
      ),
      MissionScenario(
        missionId: 'coc4_m5',
        cocId: 'coc4',
        missionNumber: 5,
        missionTitle: 'Apply Repair Action and Create Report',
        moduleName: 'Troubleshooting and Repair Quest',
        scenario:
            'After diagnosing various problems, you must select the correct repair solution for each issue and document the troubleshooting process in a service report.',
        objective:
            'Choose the appropriate repair action for each problem and complete proper documentation.',
        skillsAssessed: [
          'Solution selection',
          'Repair procedures',
          'Technical documentation',
          'Service reporting',
        ],
        challengeDescription:
            'Select correct repair actions and demonstrate proper documentation skills.',
        difficulty: 'Hard',
        xpReward: 0,
        estimatedTime: 25,
        passingScore: 0,
      ),
    ];
  }

  // ==========================================
  // COC 1 Mission 1 Hints Data
  // ==========================================
  static List<MissionHint> getCOC1M1Hints() {
    return [
      MissionHint(
        itemId: 'motherboard',
        hintText:
            'This is the largest circuit board where many internal components are connected.',
      ),
      MissionHint(
        itemId: 'cpu',
        hintText:
            'This small square chip is considered the brain of the computer.',
      ),
      MissionHint(
        itemId: 'ram',
        hintText:
            'This long module temporarily stores active data while the computer is running.',
      ),
      MissionHint(
        itemId: 'psu',
        hintText: 'This component supplies power to all parts of the computer.',
      ),
      MissionHint(
        itemId: 'ssd',
        hintText:
            'This device stores files, applications, and the operating system permanently.',
      ),
      MissionHint(
        itemId: 'hdd',
        hintText:
            'This storage device has spinning platters and uses magnetic storage.',
      ),
      MissionHint(
        itemId: 'gpu',
        hintText:
            'This expansion card processes graphics and images for display.',
      ),
      MissionHint(
        itemId: 'cooling_fan',
        hintText: 'This component helps dissipate heat from the system.',
      ),
      MissionHint(
        itemId: 'heatsink',
        hintText:
            'This metal component sits on top of the CPU to absorb and transfer heat.',
      ),
      MissionHint(
        itemId: 'monitor',
        hintText: 'This output device displays what the computer is doing.',
      ),
      MissionHint(
        itemId: 'keyboard',
        hintText: 'This input device is used for typing text and commands.',
      ),
      MissionHint(
        itemId: 'mouse',
        hintText:
            'This input device is used to move the pointer and click items.',
      ),
      MissionHint(
        itemId: 'screwdriver',
        hintText:
            'This tool is used to tighten or loosen screws during assembly.',
      ),
      MissionHint(
        itemId: 'anti_static_wrist_strap',
        hintText:
            'This safety tool helps prevent electrostatic discharge while handling components.',
      ),
      MissionHint(
        itemId: 'power_cable',
        hintText: 'This cable connects the computer to an electrical outlet.',
      ),
      MissionHint(
        itemId: 'sata_cable',
        hintText:
            'This cable connects storage devices to the motherboard for data transfer.',
      ),
    ];
  }

  /// Get hint for a specific item
  static String? getHintForItem(String itemId) {
    try {
      final hint = getCOC1M1Hints().firstWhere((h) => h.itemId == itemId);
      return hint.hintText;
    } catch (e) {
      return null;
    }
  }
}
