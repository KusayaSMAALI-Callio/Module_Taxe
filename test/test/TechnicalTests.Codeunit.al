codeunit 50253 "CAGTX_TechnicalTests"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        TechnicalTestsHelper: Codeunit CAGTX_TechnicalTestsHelper;
        PermissionTestMgt: Codeunit "CAGTX_Permission Test Mgt";

    [Test]
    procedure TestTableRelations()
    begin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        TechnicalTestsHelper.TestTableRelations(8062606, 8062645);
        TechnicalTestsHelper.TestTableRelations(8062958, 8062987);
    end;

    [Test]
    procedure TestTransferFields()
    begin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        TechnicalTestsHelper.TestTransferfields(Database::"CAGTX_Doc. Tax Buffer", Database::"CAGTX_Sales Doc. Tax Detail");
        TechnicalTestsHelper.TestTransferfields(Database::"CAGTX_Doc. Tax Buffer", Database::"CAGTX_Purch. Doc. Tax Detail");
        TechnicalTestsHelper.TestTransferfields(Database::"CAGTX_Doc. Tax Buffer", Database::"CAGTX_Service Doc. Tax Detail");
    end;
}

