import '../models/mission_model.dart';

/// Hardware Item Model for Identification Missions
class HardwareItem {
  final String id;
  final String name;
  final String imagePath;

  HardwareItem({
    required this.id,
    required this.name,
    required this.imagePath,
  });
}

/// Mission Content Data
/// Contains questions, components, steps, and scenarios for all missions
class MissionContentData {
  // ==========================================
  // COC 1 MISSION 1: Identify Computer Parts - WITH REAL IMAGES
  // ==========================================

  /// Hardware Items for COC 1 Mission 1
  static List<HardwareItem> getCOC1M1Items() {
    return [
      HardwareItem(
        id: 'motherboard',
        name: 'Motherboard',
        imagePath: 'assets/COC1/Mission 1/motherboard.png',
      ),
      HardwareItem(
        id: 'cpu',
        name: 'CPU',
        imagePath: 'assets/COC1/Mission 1/cpu.png',
      ),
      HardwareItem(
        id: 'ram',
        name: 'RAM',
        imagePath: 'assets/COC1/Mission 1/ram.png',
      ),
      HardwareItem(
        id: 'ssd',
        name: 'SSD',
        imagePath: 'assets/COC1/Mission 1/ssd.png',
      ),
      HardwareItem(
        id: 'hdd',
        name: 'HDD',
        imagePath: 'assets/COC1/Mission 1/hdd.png',
      ),
      HardwareItem(
        id: 'psu',
        name: 'PSU',
        imagePath: 'assets/COC1/Mission 1/psu.png',
      ),
      HardwareItem(
        id: 'keyboard',
        name: 'Keyboard',
        imagePath: 'assets/COC1/Mission 1/keyboard.png',
      ),
      HardwareItem(
        id: 'mouse',
        name: 'Mouse',
        imagePath: 'assets/COC1/Mission 1/mouse.png',
      ),
      HardwareItem(
        id: 'monitor',
        name: 'Monitor',
        imagePath: 'assets/COC1/Mission 1/monitor.png',
      ),
      HardwareItem(
        id: 'screwdriver',
        name: 'Screwdriver',
        imagePath: 'assets/COC1/Mission 1/screwdriver.png',
      ),
      HardwareItem(
        id: 'anti_static_strap',
        name: 'Anti-static Strap',
        imagePath: 'assets/COC1/Mission 1/anti_static_wrist_strap.png',
      ),
      HardwareItem(
        id: 'not_sure',
        name: 'Not sure',
        imagePath: '',
      ),
    ];
  }

  /// Questions for COC 1 Mission 1 - Using Image-Based Identification
  static List<MissionQuestion> getCOC1M1Questions() {
    return [
      MissionQuestion(
        id: 'q1',
        question: 'Select the RAM (Random Access Memory)',
        options: [
          'Motherboard',
          'CPU',
          'RAM',
          'SSD',
          'HDD',
          'PSU',
          'Keyboard',
          'Mouse',
          'Monitor',
          'Screwdriver',
          'Anti-static Strap',
          'Not sure'
        ],
        correctAnswer: 'RAM',
        explanation:
            'RAM is the temporary memory where data is stored for quick access by the CPU.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q2',
        question: 'Select the Power Supply Unit (PSU)',
        options: [
          'Motherboard',
          'CPU',
          'RAM',
          'SSD',
          'HDD',
          'PSU',
          'Keyboard',
          'Mouse',
          'Monitor',
          'Screwdriver',
          'Anti-static Strap',
          'Not sure'
        ],
        correctAnswer: 'PSU',
        explanation:
            'The PSU converts AC power to DC power for computer components.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q3',
        question: 'Select the Anti-static Strap',
        options: [
          'Motherboard',
          'CPU',
          'RAM',
          'SSD',
          'HDD',
          'PSU',
          'Keyboard',
          'Mouse',
          'Monitor',
          'Screwdriver',
          'Anti-static Strap',
          'Not sure'
        ],
        correctAnswer: 'Anti-static Strap',
        explanation:
            'Anti-static wrist straps prevent static electricity from damaging components.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q4',
        question: 'Select the Motherboard',
        options: [
          'Motherboard',
          'CPU',
          'RAM',
          'SSD',
          'HDD',
          'PSU',
          'Keyboard',
          'Mouse',
          'Monitor',
          'Screwdriver',
          'Anti-static Strap',
          'Not sure'
        ],
        correctAnswer: 'Motherboard',
        explanation:
            'The motherboard is the main circuit board that connects all components.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q5',
        question: 'Select the Central Processing Unit (CPU)',
        options: [
          'Motherboard',
          'CPU',
          'RAM',
          'SSD',
          'HDD',
          'PSU',
          'Keyboard',
          'Mouse',
          'Monitor',
          'Screwdriver',
          'Anti-static Strap',
          'Not sure'
        ],
        correctAnswer: 'CPU',
        explanation:
            'The CPU is the brain of the computer that processes instructions.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q6',
        question: 'Select the Solid State Drive (SSD)',
        options: [
          'Motherboard',
          'CPU',
          'RAM',
          'SSD',
          'HDD',
          'PSU',
          'Keyboard',
          'Mouse',
          'Monitor',
          'Screwdriver',
          'Anti-static Strap',
          'Not sure'
        ],
        correctAnswer: 'SSD',
        explanation:
            'SSDs are fast storage devices that permanently store data.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q7',
        question: 'Select the Hard Disk Drive (HDD)',
        options: [
          'Motherboard',
          'CPU',
          'RAM',
          'SSD',
          'HDD',
          'PSU',
          'Keyboard',
          'Mouse',
          'Monitor',
          'Screwdriver',
          'Anti-static Strap',
          'Not sure'
        ],
        correctAnswer: 'HDD',
        explanation:
            'HDDs are traditional magnetic storage devices used for large volumes of data.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q8',
        question: 'Select the Screwdriver',
        options: [
          'Motherboard',
          'CPU',
          'RAM',
          'SSD',
          'HDD',
          'PSU',
          'Keyboard',
          'Mouse',
          'Monitor',
          'Screwdriver',
          'Anti-static Strap',
          'Not sure'
        ],
        correctAnswer: 'Screwdriver',
        explanation:
            'Screwdrivers are essential tools for assembling computers.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q9',
        question: 'Select the Monitor',
        options: [
          'Motherboard',
          'CPU',
          'RAM',
          'SSD',
          'HDD',
          'PSU',
          'Keyboard',
          'Mouse',
          'Monitor',
          'Screwdriver',
          'Anti-static Strap',
          'Not sure'
        ],
        correctAnswer: 'Monitor',
        explanation:
            'The monitor is the display device that shows visual output.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q10',
        question: 'Select the Keyboard',
        options: [
          'Motherboard',
          'CPU',
          'RAM',
          'SSD',
          'HDD',
          'PSU',
          'Keyboard',
          'Mouse',
          'Monitor',
          'Screwdriver',
          'Anti-static Strap',
          'Not sure'
        ],
        correctAnswer: 'Keyboard',
        explanation:
            'A keyboard is an input device used to type text and commands into the computer.',
        points: 10,
      ),
    ];
  }

  // ==========================================
  // COC 1 MISSION 2: Install Internal Components
  // ==========================================
  static List<DraggableComponent> getCOC1M2Components() {
    return [
      DraggableComponent(
        id: 'motherboard',
        name: 'Motherboard',
        targetZone: 'case',
        description: 'Install motherboard into the case first',
      ),
      DraggableComponent(
        id: 'cpu',
        name: 'CPU',
        targetZone: 'cpu_socket',
        description: 'Place CPU into the CPU socket on motherboard',
      ),
      DraggableComponent(
        id: 'cpu_cooler',
        name: 'CPU Cooler',
        targetZone: 'cpu_area',
        description: 'Install cooling fan on top of CPU',
      ),
      DraggableComponent(
        id: 'ram',
        name: 'RAM Module',
        targetZone: 'ram_slot',
        description: 'Insert RAM into memory slots',
      ),
      DraggableComponent(
        id: 'storage',
        name: 'Storage Drive',
        targetZone: 'drive_bay',
        description: 'Mount storage device in drive bay',
      ),
    ];
  }

  static List<DropZone> getCOC1M2DropZones() {
    return [
      DropZone(
        id: 'case',
        name: 'System Unit Case',
        acceptedComponents: ['motherboard'],
      ),
      DropZone(
        id: 'cpu_socket',
        name: 'CPU Socket',
        acceptedComponents: ['cpu'],
      ),
      DropZone(
        id: 'cpu_area',
        name: 'CPU Cooling Area',
        acceptedComponents: ['cpu_cooler'],
      ),
      DropZone(
        id: 'ram_slot',
        name: 'RAM Slots',
        acceptedComponents: ['ram'],
      ),
      DropZone(
        id: 'drive_bay',
        name: 'Drive Bay',
        acceptedComponents: ['storage'],
      ),
    ];
  }

  // ==========================================
  // COC 1 MISSION 3: Connect Power and Data Cables
  // ==========================================
  static List<DraggableComponent> getCOC1M3Components() {
    return [
      DraggableComponent(
        id: '24pin_cable',
        name: '24-Pin ATX Cable',
        targetZone: 'motherboard_power',
        description: 'Main power connector for motherboard',
      ),
      DraggableComponent(
        id: 'cpu_power',
        name: 'CPU Power Cable',
        targetZone: 'cpu_power_port',
        description: '4-pin or 8-pin CPU power connector',
      ),
      DraggableComponent(
        id: 'sata_data',
        name: 'SATA Data Cable',
        targetZone: 'storage_data',
        description: 'Connects storage to motherboard',
      ),
      DraggableComponent(
        id: 'sata_power',
        name: 'SATA Power Cable',
        targetZone: 'storage_power',
        description: 'Powers the storage device',
      ),
      DraggableComponent(
        id: 'front_panel',
        name: 'Front Panel Connector',
        targetZone: 'front_panel_pins',
        description: 'Connects case buttons and LEDs',
      ),
    ];
  }

  static List<DropZone> getCOC1M3DropZones() {
    return [
      DropZone(
        id: 'motherboard_power',
        name: 'Motherboard 24-Pin Port',
        acceptedComponents: ['24pin_cable'],
      ),
      DropZone(
        id: 'cpu_power_port',
        name: 'CPU Power Port',
        acceptedComponents: ['cpu_power'],
      ),
      DropZone(
        id: 'storage_data',
        name: 'Storage SATA Port',
        acceptedComponents: ['sata_data'],
      ),
      DropZone(
        id: 'storage_power',
        name: 'Storage Power Port',
        acceptedComponents: ['sata_power'],
      ),
      DropZone(
        id: 'front_panel_pins',
        name: 'Front Panel Header',
        acceptedComponents: ['front_panel'],
      ),
    ];
  }

  // ==========================================
  // COC 1 MISSION 4: Configure BIOS
  // ==========================================
  static Map<String, dynamic> getCOC1M4ConfigData() {
    return {
      'bootPriority': {
        'question': 'Set the correct boot device priority',
        'options': ['Hard Drive', 'USB Drive', 'CD/DVD Drive', 'Network'],
        'correctAnswer': 'Hard Drive',
        'points': 20,
      },
      'detectedHardware': {
        'question': 'Verify all hardware is detected',
        'items': ['CPU', 'RAM', 'Storage', 'Network Card'],
        'points': 20,
      },
      'osInstallation': {
        'steps': [
          'Select language and keyboard',
          'Accept license agreement',
          'Choose installation type',
          'Select partition/drive',
          'Begin installation',
          'Set up user account',
          'Complete setup',
        ],
        'points': 40,
      },
    };
  }

  // ==========================================
  // COC 1 MISSION 5: Install Drivers and Test
  // ==========================================
  static List<ProcedureStep> getCOC1M5Steps() {
    return [
      ProcedureStep(
        id: 'step1',
        order: 1,
        title: 'Install LAN Driver',
        description: 'Install network adapter driver for internet connectivity',
        points: 10,
      ),
      ProcedureStep(
        id: 'step2',
        order: 2,
        title: 'Install Audio Driver',
        description: 'Install sound card driver for audio functionality',
        points: 10,
      ),
      ProcedureStep(
        id: 'step3',
        order: 3,
        title: 'Install Graphics Driver',
        description: 'Install display adapter driver for optimal graphics',
        points: 10,
      ),
      ProcedureStep(
        id: 'step4',
        order: 4,
        title: 'Install Chipset Driver',
        description: 'Install motherboard chipset driver',
        points: 10,
      ),
      ProcedureStep(
        id: 'step5',
        order: 5,
        title: 'Test Display',
        description: 'Verify monitor displays correctly',
        points: 10,
      ),
      ProcedureStep(
        id: 'step6',
        order: 6,
        title: 'Test Keyboard',
        description: 'Verify keyboard input works',
        points: 10,
      ),
      ProcedureStep(
        id: 'step7',
        order: 7,
        title: 'Test Mouse',
        description: 'Verify mouse pointer movement and clicks',
        points: 10,
      ),
      ProcedureStep(
        id: 'step8',
        order: 8,
        title: 'Test Audio',
        description: 'Play test sound to verify audio output',
        points: 10,
      ),
      ProcedureStep(
        id: 'step9',
        order: 9,
        title: 'Test Network',
        description: 'Connect to network and test internet access',
        points: 10,
      ),
      ProcedureStep(
        id: 'step10',
        order: 10,
        title: 'Verify All Tests Passed',
        description: 'Confirm all hardware tests completed successfully',
        points: 10,
      ),
    ];
  }

  /// Hardware Items for COC 2 Mission 1
  static List<HardwareItem> getCOC2M1Items() {
    return [
      HardwareItem(
        id: 'router',
        name: 'Router',
        imagePath: 'assets/COC2/Mission 1/Router.png',
      ),
      HardwareItem(
        id: 'switch',
        name: 'Switch',
        imagePath: 'assets/COC2/Mission 1/Switch.png',
      ),
      HardwareItem(
        id: 'modem',
        name: 'Modem',
        imagePath: 'assets/COC2/Mission 1/Modem.png',
      ),
      HardwareItem(
        id: 'lan_cable',
        name: 'LAN Cable',
        imagePath: 'assets/COC2/Mission 1/Lan Cable.png',
      ),
      HardwareItem(
        id: 'rj45_connector',
        name: 'RJ45 Connector',
        imagePath: 'assets/COC2/Mission 1/RJ45 Connector.png',
      ),
      HardwareItem(
        id: 'nic',
        name: 'NIC',
        imagePath: 'assets/COC2/Mission 1/NIC.png',
      ),
      HardwareItem(
        id: 'crimping_tool',
        name: 'Crimping Tool',
        imagePath: 'assets/COC2/Mission 1/Crimping Tool.png',
      ),
      HardwareItem(
        id: 'wire_stripper',
        name: 'Wire Stripper',
        imagePath: 'assets/COC2/Mission 1/Wire Stripper.png',
      ),
      HardwareItem(
        id: 'lan_tester',
        name: 'LAN Tester',
        imagePath: 'assets/COC2/Mission 1/LAN Tester.png',
      ),
    ];
  }

  // ==========================================
  // COC 2 MISSION 1: Identify Network Devices
  // ==========================================
  static List<MissionQuestion> getCOC2M1Questions() {
    final allOptions = [
      'Router',
      'Switch',
      'Modem',
      'LAN Cable',
      'RJ45 Connector',
      'NIC',
      'Crimping Tool',
      'Wire Stripper',
      'LAN Tester',
    ];

    return [
      MissionQuestion(
        id: 'q1',
        question: 'Select the Router',
        options: allOptions,
        correctAnswer: 'Router',
        explanation:
            'A router connects multiple networks and directs traffic between them.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q2',
        question: 'Select the Network Switch',
        options: allOptions,
        correctAnswer: 'Switch',
        explanation: 'A switch connects devices within a single network.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q3',
        question: 'Select the Modem',
        options: allOptions,
        correctAnswer: 'Modem',
        explanation:
            'A modem converts digital signals for internet transmission.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q4',
        question: 'Select the LAN Cable (Ethernet Cable)',
        options: allOptions,
        correctAnswer: 'LAN Cable',
        explanation:
            'LAN cables (Cat5e/Cat6) are used for wired network connections.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q5',
        question: 'Select the RJ45 Connector',
        options: allOptions,
        correctAnswer: 'RJ45 Connector',
        explanation: 'RJ45 is the standard connector for Ethernet cables.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q6',
        question: 'Select the Network Interface Card (NIC)',
        options: allOptions,
        correctAnswer: 'NIC',
        explanation: 'NIC allows a computer to connect to a network.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q7',
        question: 'Select the Crimping Tool',
        options: allOptions,
        correctAnswer: 'Crimping Tool',
        explanation: 'Crimping tools attach RJ45 connectors to cables.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q8',
        question: 'Select the Wire Stripper',
        options: allOptions,
        correctAnswer: 'Wire Stripper',
        explanation: 'Wire strippers remove cable insulation.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q9',
        question: 'Select the LAN Cable Tester',
        options: allOptions,
        correctAnswer: 'LAN Tester',
        explanation: 'LAN testers verify cable connectivity and wiring.',
        points: 10,
      ),
    ];
  }

  // ==========================================
  // COC 2 MISSION 2: Create Network Cables (T568B)
  // ==========================================
  static List<String> getCOC2M2WireSequence() {
    return [
      'White-Orange',
      'Orange',
      'White-Green',
      'Blue',
      'White-Blue',
      'Green',
      'White-Brown',
      'Brown',
    ];
  }

  // ==========================================
  // COC 2 MISSION 3: Test Cable
  // ==========================================
  static List<ProcedureStep> getCOC2M3Steps() {
    return [
      ProcedureStep(
        id: 'step1',
        order: 1,
        title: 'Connect Cable to Tester',
        description: 'Plug both ends of cable into LAN tester ports',
        points: 20,
      ),
      ProcedureStep(
        id: 'step2',
        order: 2,
        title: 'Power On Tester',
        description: 'Turn on the LAN cable tester',
        points: 20,
      ),
      ProcedureStep(
        id: 'step3',
        order: 3,
        title: 'Observe Light Sequence',
        description: 'Watch the LED indicators light up in sequence (1-8)',
        points: 30,
      ),
      ProcedureStep(
        id: 'step4',
        order: 4,
        title: 'Verify Results',
        description:
            'Check if all 8 lights blink in correct order (Pass) or identify faults',
        points: 30,
      ),
    ];
  }

  // ==========================================
  // COC 2 MISSION 4: Connect LAN Devices
  // ==========================================
  static List<DraggableComponent> getCOC2M4Components() {
    return [
      DraggableComponent(
        id: 'computer',
        name: 'Computer',
        targetZone: 'switch_port',
        description: 'Connect computer to switch',
      ),
      DraggableComponent(
        id: 'switch',
        name: 'Network Switch',
        targetZone: 'router_lan',
        description: 'Connect switch to router',
      ),
      DraggableComponent(
        id: 'router',
        name: 'Router',
        targetZone: 'modem',
        description: 'Connect router to modem',
      ),
    ];
  }

  // ==========================================
  // COC 2 MISSION 5: Configure IP Settings
  // ==========================================
  static Map<String, dynamic> getCOC2M5ConfigData() {
    return {
      'ipAddress': {
        'question': 'Enter a valid IP Address',
        'correctAnswer': '192.168.1.100',
        'validation':
            r'^192\.168\.1\.(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$',
        'points': 25,
      },
      'subnetMask': {
        'question': 'Enter the Subnet Mask',
        'correctAnswer': '255.255.255.0',
        'validation': r'^255\.255\.255\.0$',
        'points': 25,
      },
      'gateway': {
        'question': 'Enter the Default Gateway',
        'correctAnswer': '192.168.1.1',
        'validation': r'^192\.168\.1\.1$',
        'points': 25,
      },
      'dns': {
        'question': 'Enter the DNS Server',
        'correctAnswer': '8.8.8.8',
        'validation': r'^8\.8\.8\.8$',
        'points': 25,
      },
    };
  }

  // ==========================================
  // COC 3 MISSION 1: Server Setup Requirements
  // ==========================================
  static List<MissionQuestion> getCOC3M1Questions() {
    return [
      MissionQuestion(
        id: 'q1',
        question: 'Select Server Hardware',
        options: ['Gaming PC', 'Server Hardware', 'Laptop', 'Tablet'],
        correctAnswer: 'Server Hardware',
        explanation:
            'Server-grade hardware is designed for reliability and performance.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q2',
        question: 'Select Client Computer',
        options: ['Server', 'Client Computer', 'Router', 'Switch'],
        correctAnswer: 'Client Computer',
        explanation: 'Client computers access server resources.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q3',
        question: 'Select Server OS Installer',
        options: [
          'Game Disc',
          'Server OS Installer',
          'Application CD',
          'Driver Disc'
        ],
        correctAnswer: 'Server OS Installer',
        explanation:
            'Server OS installer contains the server operating system.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q4',
        question: 'Select Network Connection',
        options: ['Bluetooth', 'Network Connection', 'USB Cable', 'HDMI'],
        correctAnswer: 'Network Connection',
        explanation: 'Network connection enables client-server communication.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q5',
        question: 'Select Configuration Checklist',
        options: [
          'User Manual',
          'Configuration Checklist',
          'Warranty Card',
          'Receipt'
        ],
        correctAnswer: 'Configuration Checklist',
        explanation: 'Checklist ensures all setup steps are completed.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q6',
        question: 'Select UPS (Uninterruptible Power Supply)',
        options: ['Power Strip', 'UPS', 'Extension Cord', 'Adapter'],
        correctAnswer: 'UPS',
        explanation: 'UPS provides backup power during outages.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q7',
        question: 'Select Network Cables',
        options: ['HDMI Cable', 'Network Cables', 'USB Cable', 'Audio Cable'],
        correctAnswer: 'Network Cables',
        explanation: 'Network cables connect server to network infrastructure.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q8',
        question: 'Select Server Rack (if applicable)',
        options: ['Desk', 'Server Rack', 'Shelf', 'Floor'],
        correctAnswer: 'Server Rack',
        explanation: 'Server racks organize and secure server equipment.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q9',
        question: 'Select Backup Storage',
        options: ['USB Flash Drive', 'Backup Storage', 'SD Card', 'Phone'],
        correctAnswer: 'Backup Storage',
        explanation: 'Backup storage protects against data loss.',
        points: 10,
      ),
      MissionQuestion(
        id: 'q10',
        question: 'Select Documentation',
        options: ['Magazine', 'Server Documentation', 'Novel', 'Poster'],
        correctAnswer: 'Server Documentation',
        explanation: 'Documentation guides server setup and configuration.',
        points: 10,
      ),
    ];
  }

  // ==========================================
  // COC 3 MISSION 2: Install Server OS
  // ==========================================
  static List<ProcedureStep> getCOC3M2Steps() {
    return [
      ProcedureStep(
        id: 'step1',
        order: 1,
        title: 'Boot from Installer',
        description: 'Insert installer and boot from installation media',
        points: 10,
      ),
      ProcedureStep(
        id: 'step2',
        order: 2,
        title: 'Accept License Agreement',
        description: 'Read and accept the software license terms',
        points: 10,
      ),
      ProcedureStep(
        id: 'step3',
        order: 3,
        title: 'Choose Installation Type',
        description: 'Select clean installation or upgrade',
        points: 15,
      ),
      ProcedureStep(
        id: 'step4',
        order: 4,
        title: 'Select Installation Drive',
        description: 'Choose the drive where server OS will be installed',
        points: 15,
      ),
      ProcedureStep(
        id: 'step5',
        order: 5,
        title: 'Set Server Name',
        description: 'Enter a descriptive name for the server',
        points: 10,
      ),
      ProcedureStep(
        id: 'step6',
        order: 6,
        title: 'Configure Time Zone',
        description: 'Set the correct time zone for server location',
        points: 10,
      ),
      ProcedureStep(
        id: 'step7',
        order: 7,
        title: 'Create Administrator Account',
        description: 'Set up administrator username and password',
        points: 15,
      ),
      ProcedureStep(
        id: 'step8',
        order: 8,
        title: 'Complete Installation',
        description: 'Wait for installation to finish and restart',
        points: 15,
      ),
    ];
  }

  // ==========================================
  // COC 4 MISSION 1: Identify Problems
  // ==========================================
  static List<Map<String, dynamic>> getCOC4M1Scenarios() {
    return [
      {
        'symptom': 'No display on monitor',
        'causes': [
          'Loose display cable',
          'RAM not seated',
          'Power issue',
          'Broken mouse'
        ],
        'correctCause': 'Loose display cable',
        'points': 10,
      },
      {
        'symptom': 'Computer is very slow',
        'causes': [
          'Too many startup programs',
          'Low storage space',
          'Good RAM',
          'Fast CPU'
        ],
        'correctCause': 'Too many startup programs',
        'points': 10,
      },
      {
        'symptom': 'No internet connection',
        'causes': [
          'Wrong IP address',
          'Correct DNS',
          'Good cable',
          'Fast speed'
        ],
        'correctCause': 'Wrong IP address',
        'points': 10,
      },
      {
        'symptom': 'Computer overheating',
        'causes': [
          'Clean fans',
          'Dusty cooling fan',
          'Good airflow',
          'Low temperature'
        ],
        'correctCause': 'Dusty cooling fan',
        'points': 10,
      },
      {
        'symptom': 'Cannot print documents',
        'causes': [
          'Printer driver missing',
          'Paper loaded',
          'Ink full',
          'Cable connected'
        ],
        'correctCause': 'Printer driver missing',
        'points': 10,
      },
      {
        'symptom': 'Blue screen errors',
        'causes': ['Faulty RAM', 'Good drivers', 'Clean system', 'Fast SSD'],
        'correctCause': 'Faulty RAM',
        'points': 10,
      },
      {
        'symptom': 'System won\'t boot',
        'causes': [
          'Wrong boot order',
          'Good BIOS',
          'Detected HDD',
          'Working PSU'
        ],
        'correctCause': 'Wrong boot order',
        'points': 10,
      },
      {
        'symptom': 'No sound output',
        'causes': [
          'Audio driver issue',
          'Good speakers',
          'Volume up',
          'Cable OK'
        ],
        'correctCause': 'Audio driver issue',
        'points': 10,
      },
      {
        'symptom': 'Keyboard not working',
        'causes': [
          'USB port issue',
          'Good connection',
          'Clean keys',
          'New keyboard'
        ],
        'correctCause': 'USB port issue',
        'points': 10,
      },
      {
        'symptom': 'Network is very slow',
        'causes': [
          'Network congestion',
          'Fast router',
          'Good cable',
          'Strong signal'
        ],
        'correctCause': 'Network congestion',
        'points': 10,
      },
    ];
  }

  // ==========================================
  // COC 4 MISSION 2: Preventive Maintenance
  // ==========================================
  static List<ProcedureStep> getCOC4M2Steps() {
    return [
      ProcedureStep(
        id: 'step1',
        order: 1,
        title: 'Turn Off Computer',
        description: 'Shut down the system properly',
        points: 10,
      ),
      ProcedureStep(
        id: 'step2',
        order: 2,
        title: 'Unplug Power Cable',
        description: 'Disconnect power to ensure safety',
        points: 10,
      ),
      ProcedureStep(
        id: 'step3',
        order: 3,
        title: 'Wear Anti-Static Protection',
        description: 'Put on anti-static wrist strap',
        points: 10,
      ),
      ProcedureStep(
        id: 'step4',
        order: 4,
        title: 'Open System Case',
        description: 'Remove side panel to access components',
        points: 10,
      ),
      ProcedureStep(
        id: 'step5',
        order: 5,
        title: 'Clean Dust with Compressed Air',
        description: 'Blow dust from components and fans',
        points: 10,
      ),
      ProcedureStep(
        id: 'step6',
        order: 6,
        title: 'Check Cooling Fans',
        description: 'Verify fans spin freely and are clean',
        points: 10,
      ),
      ProcedureStep(
        id: 'step7',
        order: 7,
        title: 'Inspect Cables',
        description: 'Check all cables are secure and organized',
        points: 10,
      ),
      ProcedureStep(
        id: 'step8',
        order: 8,
        title: 'Reseat Components',
        description: 'Ensure RAM and cards are properly seated',
        points: 10,
      ),
      ProcedureStep(
        id: 'step9',
        order: 9,
        title: 'Close Case',
        description: 'Replace side panel and secure screws',
        points: 10,
      ),
      ProcedureStep(
        id: 'step10',
        order: 10,
        title: 'Test System',
        description: 'Power on and verify everything works',
        points: 10,
      ),
    ];
  }
}
