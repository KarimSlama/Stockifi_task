abstract class OrganizationService {
  String? selectedSubsidiaryId;
}

class OrganizationServiceImpl implements OrganizationService {
  @override
  String? selectedSubsidiaryId;
}

class MockOrganizationService implements OrganizationService {
  @override
  String? selectedSubsidiaryId;
}
