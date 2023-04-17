codeunit 8062606 "CAGTX_Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "CAGTX_Upgrade Tag Definitions";
    begin
        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.CAGTX_GetSwitchItemTaxTableUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.CAGTX_GetSwitchItemTaxTableUpgradeTag());
    end;

    trigger OnInstallAppPerDatabase();
    var
        AppAccessMgt: Codeunit CAGTX_AppAccessMgt;
    begin
        AppAccessMgt.SetAppDataInIsolatedStorageOnInstall();
    end;
}
