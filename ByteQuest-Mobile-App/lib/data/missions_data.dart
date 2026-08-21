import '../models/mission_model.dart';

/// Complete Mission Data for CSS NC II COC 1-4
/// Total: 20 Missions (5 per COC)
class MissionsData {
  /// All Missions List
  static List<Mission> getAllMissions() {
    return [
      // COC 1: Install and Configure Computer Systems
      ...getCOC1Missions(),
      // COC 2: Set Up Computer Networks
      ...getCOC2Missions(),
      // COC 3: Set Up Computer Servers
      ...getCOC3Missions(),
      // COC 4: Maintain and Repair Computer Systems and Networks
      ...getCOC4Missions(),
    ];
  }

  /// COC 1 Missions
  static List<Mission> getCOC1Missions() {
    return [
      Mission(
        id: 'coc1_m1',
        cocId: 'coc1',
        missionCode: 'COC1-M1',
        missionNumber: 1,
        orderIndex: 1,
        title: 'Identify Computer Parts and Tools',
        description:
            'Learn to identify essential computer components, peripherals, and tools used in computer assembly and maintenance.',
        missionType: MissionType.identification,
        xpReward: 0,
        passingScore: 0,
        isUnlocked: true,
        difficulty: 'Easy',
        estimatedTimeMinutes: 10,
      ),
      Mission(
        id: 'coc1_m2',
        cocId: 'coc1',
        missionCode: 'COC1-M2',
        missionNumber: 2,
        orderIndex: 2,
        title: 'Install Internal Components',
        description:
            'Practice installing motherboard, CPU, RAM, storage devices, and cooling systems into the computer case.',
        missionType: MissionType.dragAndDrop,
        xpReward: 0,
        passingScore: 0,
        isUnlocked: false,
        difficulty: 'Medium',
        estimatedTimeMinutes: 20,
      ),
      Mission(
        id: 'coc1_m3',
        cocId: 'coc1',
        missionCode: 'COC1-M3',
        missionNumber: 3,
        orderIndex: 3,
        title: 'Connect Power and Data Cables',
        description:
            'Learn proper cable management and connect power and data cables to motherboard and components.',
        missionType: MissionType.dragAndDrop,
        xpReward: 0,
        passingScore: 0,
        isUnlocked: false,
        difficulty: 'Medium',
        estimatedTimeMinutes: 15,
      ),
      Mission(
        id: 'coc1_m4',
        cocId: 'coc1',
        missionCode: 'COC1-M4',
        missionNumber: 4,
        orderIndex: 4,
        title: 'Configure BIOS/UEFI and Install OS',
        description:
            'Access BIOS/UEFI settings, configure boot priority, and follow OS installation procedures.',
        missionType: MissionType.configurationForm,
        xpReward: 0,
        passingScore: 0,
        isUnlocked: false,
        difficulty: 'Hard',
        estimatedTimeMinutes: 25,
      ),
      Mission(
        id: 'coc1_m5',
        cocId: 'coc1',
        missionCode: 'COC1-M5',
        missionNumber: 5,
        orderIndex: 5,
        title: 'Install Drivers and Test the System',
        description:
            'Install necessary drivers and perform system tests to ensure all components work correctly.',
        missionType: MissionType.stepProcedure,
        xpReward: 0,
        passingScore: 0,
        isUnlocked: false,
        difficulty: 'Medium',
        estimatedTimeMinutes: 20,
      ),
    ];
  }

  /// COC 2 Missions
  static List<Mission> getCOC2Missions() {
    return [
      Mission(
        id: 'coc2_m1',
        cocId: 'coc2',
        missionCode: 'COC2-M1',
        missionNumber: 1,
        orderIndex: 1,
        title: 'Identify Network Devices and Tools',
        description:
            'Recognize routers, switches, modems, cables, connectors, and network tools.',
        missionType: MissionType.identification,
        xpReward: 0,
        passingScore: 0,
        isUnlocked: false,
        difficulty: 'Easy',
        estimatedTimeMinutes: 10,
      ),
      Mission(
        id: 'coc2_m2',
        cocId: 'coc2',
        missionCode: 'COC2-M2',
        missionNumber: 2,
        orderIndex: 2,
        title: 'Create Network Cables',
        description:
            'Arrange Ethernet cable wires in correct sequence following T568B standard.',
        missionType: MissionType.dragAndDrop,
        xpReward: 0,
        passingScore: 0,
        isUnlocked: false,
        difficulty: 'Medium',
        estimatedTimeMinutes: 15,
      ),
      Mission(
        id: 'coc2_m3',
        cocId: 'coc2',
        missionCode: 'COC2-M3',
        missionNumber: 3,
        orderIndex: 3,
        title: 'Test Cable Connectivity',
        description:
            'Use LAN tester simulation to verify cable connections and identify faults.',
        missionType: MissionType.stepProcedure,
        xpReward: 0,
        passingScore: 0,
        isUnlocked: false,
        difficulty: 'Easy',
        estimatedTimeMinutes: 10,
      ),
      Mission(
        id: 'coc2_m4',
        cocId: 'coc2',
        missionCode: 'COC2-M4',
        missionNumber: 4,
        orderIndex: 4,
        title: 'Connect Devices in Local Area Network',
        description:
            'Connect computers, switches, routers, and modems to create a functional LAN.',
        missionType: MissionType.dragAndDrop,
        xpReward: 0,
        passingScore: 0,
        isUnlocked: false,
        difficulty: 'Hard',
        estimatedTimeMinutes: 20,
      ),
      Mission(
        id: 'coc2_m5',
        cocId: 'coc2',
        missionCode: 'COC2-M5',
        missionNumber: 5,
        orderIndex: 5,
        title: 'Configure IP Settings and Test Connection',
        description:
            'Set up IP address, subnet mask, gateway, and DNS, then test network connectivity.',
        missionType: MissionType.configurationForm,
        xpReward: 0,
        passingScore: 0,
        isUnlocked: false,
        difficulty: 'Hard',
        estimatedTimeMinutes: 20,
      ),
    ];
  }

  /// COC 3 Missions
  static List<Mission> getCOC3Missions() {
    return [
      Mission(
        id: 'coc3_m1',
        cocId: 'coc3',
        missionCode: 'COC3-M1',
        missionNumber: 1,
        orderIndex: 1,
        title: 'Prepare Server Setup Requirements',
        description:
            'Identify and select required hardware, software, and documentation for server setup.',
        missionType: MissionType.identification,
        xpReward: 0,
        passingScore: 0,
        isUnlocked: false,
        difficulty: 'Medium',
        estimatedTimeMinutes: 15,
      ),
      Mission(
        id: 'coc3_m2',
        cocId: 'coc3',
        missionCode: 'COC3-M2',
        missionNumber: 2,
        orderIndex: 2,
        title: 'Install and Configure Server OS',
        description:
            'Follow step-by-step installation process for server operating system.',
        missionType: MissionType.stepProcedure,
        xpReward: 0,
        passingScore: 0,
        isUnlocked: false,
        difficulty: 'Hard',
        estimatedTimeMinutes: 25,
      ),
      Mission(
        id: 'coc3_m3',
        cocId: 'coc3',
        missionCode: 'COC3-M3',
        missionNumber: 3,
        orderIndex: 3,
        title: 'Configure Server Network Settings',
        description:
            'Set up static IP, subnet mask, gateway, and DNS for server network configuration.',
        missionType: MissionType.configurationForm,
        xpReward: 0,
        passingScore: 0,
        isUnlocked: false,
        difficulty: 'Hard',
        estimatedTimeMinutes: 20,
      ),
      Mission(
        id: 'coc3_m4',
        cocId: 'coc3',
        missionCode: 'COC3-M4',
        missionNumber: 4,
        orderIndex: 4,
        title: 'Create Users, Groups, and Permissions',
        description:
            'Manage user accounts, groups, shared folders, and access permissions on the server.',
        missionType: MissionType.configurationForm,
        xpReward: 0,
        passingScore: 0,
        isUnlocked: false,
        difficulty: 'Hard',
        estimatedTimeMinutes: 25,
      ),
      Mission(
        id: 'coc3_m5',
        cocId: 'coc3',
        missionCode: 'COC3-M5',
        missionNumber: 5,
        orderIndex: 5,
        title: 'Test Client Access and Document Setup',
        description:
            'Verify client connections and complete server setup documentation.',
        missionType: MissionType.troubleshooting,
        xpReward: 0,
        passingScore: 0,
        isUnlocked: false,
        difficulty: 'Medium',
        estimatedTimeMinutes: 20,
      ),
    ];
  }

  /// COC 4 Missions
  static List<Mission> getCOC4Missions() {
    return [
      Mission(
        id: 'coc4_m1',
        cocId: 'coc4',
        missionCode: 'COC4-M1',
        missionNumber: 1,
        orderIndex: 1,
        title: 'Identify System and Network Problems',
        description:
            'Match symptoms to their causes in computer and network troubleshooting scenarios.',
        missionType: MissionType.identification,
        xpReward: 0,
        passingScore: 0,
        isUnlocked: false,
        difficulty: 'Medium',
        estimatedTimeMinutes: 15,
      ),
      Mission(
        id: 'coc4_m2',
        cocId: 'coc4',
        missionCode: 'COC4-M2',
        missionNumber: 2,
        orderIndex: 2,
        title: 'Perform Preventive Maintenance',
        description:
            'Follow proper procedures for cleaning, inspecting, and maintaining computer systems.',
        missionType: MissionType.stepProcedure,
        xpReward: 0,
        passingScore: 0,
        isUnlocked: false,
        difficulty: 'Medium',
        estimatedTimeMinutes: 20,
      ),
      Mission(
        id: 'coc4_m3',
        cocId: 'coc4',
        missionCode: 'COC4-M3',
        missionNumber: 3,
        orderIndex: 3,
        title: 'Diagnose Hardware and Software Faults',
        description:
            'Use diagnostic decision trees to identify hardware and software problems.',
        missionType: MissionType.troubleshooting,
        xpReward: 0,
        passingScore: 0,
        isUnlocked: false,
        difficulty: 'Hard',
        estimatedTimeMinutes: 25,
      ),
      Mission(
        id: 'coc4_m4',
        cocId: 'coc4',
        missionCode: 'COC4-M4',
        missionNumber: 4,
        orderIndex: 4,
        title: 'Troubleshoot Network Issues',
        description:
            'Follow logical troubleshooting steps to resolve network connectivity problems.',
        missionType: MissionType.troubleshooting,
        xpReward: 0,
        passingScore: 0,
        isUnlocked: false,
        difficulty: 'Hard',
        estimatedTimeMinutes: 20,
      ),
      Mission(
        id: 'coc4_m5',
        cocId: 'coc4',
        missionCode: 'COC4-M5',
        missionNumber: 5,
        orderIndex: 5,
        title: 'Apply Repair Action and Create Report',
        description:
            'Select correct repair solutions and document the troubleshooting process.',
        missionType: MissionType.troubleshooting,
        xpReward: 0,
        passingScore: 0,
        isUnlocked: false,
        difficulty: 'Hard',
        estimatedTimeMinutes: 25,
      ),
    ];
  }

  /// Get missions by COC ID
  static List<Mission> getMissionsByCOC(String cocId) {
    return getAllMissions().where((m) => m.cocId == cocId).toList();
  }

  /// Get single mission by ID
  static Mission? getMissionById(String missionId) {
    try {
      return getAllMissions().firstWhere((m) => m.id == missionId);
    } catch (e) {
      return null;
    }
  }

  /// Check if mission is unlocked
  static bool isMissionUnlocked(
      String missionId, List<String> completedMissions) {
    final mission = getMissionById(missionId);
    if (mission == null) return false;

    // First mission of each COC is always unlocked if COC is unlocked
    if (mission.orderIndex == 1) {
      if (mission.cocId == 'coc1') return true;
      // Check if previous COC is at least 50% complete
      final prevCOCMissions =
          getMissionsByCOC(_getPreviousCOCId(mission.cocId));
      final prevCompleted =
          prevCOCMissions.where((m) => completedMissions.contains(m.id)).length;
      return prevCompleted >= (prevCOCMissions.length * 0.5).ceil();
    }

    // Other missions unlock when previous mission is completed
    final prevMission = getAllMissions().firstWhere(
      (m) => m.cocId == mission.cocId && m.orderIndex == mission.orderIndex - 1,
      orElse: () => mission,
    );

    return completedMissions.contains(prevMission.id);
  }

  /// Helper: Get previous COC ID
  static String _getPreviousCOCId(String cocId) {
    switch (cocId) {
      case 'coc2':
        return 'coc1';
      case 'coc3':
        return 'coc2';
      case 'coc4':
        return 'coc3';
      default:
        return 'coc1';
    }
  }

  /// Get progress statistics
  static Map<String, dynamic> getProgressStats(List<String> completedMissions) {
    final allMissions = getAllMissions();
    final total = allMissions.length;
    final completed = completedMissions.length;
    final percentage = (completed / total * 100).toInt();

    return {
      'total': total,
      'completed': completed,
      'percentage': percentage,
      'coc1': _getCOCProgress('coc1', completedMissions),
      'coc2': _getCOCProgress('coc2', completedMissions),
      'coc3': _getCOCProgress('coc3', completedMissions),
      'coc4': _getCOCProgress('coc4', completedMissions),
    };
  }

  static Map<String, dynamic> _getCOCProgress(
      String cocId, List<String> completedMissions) {
    final missions = getMissionsByCOC(cocId);
    final completed =
        missions.where((m) => completedMissions.contains(m.id)).length;
    final percentage = (completed / missions.length * 100).toInt();

    return {
      'total': missions.length,
      'completed': completed,
      'percentage': percentage,
    };
  }
}
