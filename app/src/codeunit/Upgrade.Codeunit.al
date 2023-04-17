codeunit 8062607 "CAGTX_Upgrade"
{
    Subtype = Upgrade;
    Permissions = tabledata "CAGTX_Item Tax" = RIMD,
                  tabledata "CAGTX_Item Tax V2" = RIMD;

    trigger OnUpgradePerCompany()
    begin
        SwitchItemTaxTable();
    end;

    local procedure SwitchItemTaxTable()
    var
        ItemTax: record "CAGTX_Item tax";
        ItemTaxV2: Record "CAGTX_Item Tax V2";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "CAGTX_Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.CAGTX_GetSwitchItemTaxTableUpgradeTag()) then
            exit;

        ItemTax.reset();
        if ItemTax.FindSet() then
            repeat
                ItemTaxV2.init();
                ItemTaxV2.TransferFields(ItemTax);
                ItemTaxV2.insert();
            until ItemTax.next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.CAGTX_GetSwitchItemTaxTableUpgradeTag());
    end;
}
