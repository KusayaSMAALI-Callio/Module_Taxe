codeunit 8062608 "CAGTX_Upgrade Tag Definitions"
{
    // Tag Structure - CAL-[DEVOPSID]-[Description]-[DateChangeWasDoneToSeeHowOldItWas]

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]]);
    begin
        PerCompanyUpgradeTags.Add(CAGTX_GetSwitchItemTaxTableUpgradeTag());
    end;

    procedure CAGTX_GetSwitchItemTaxTableUpgradeTag(): Code[250]
    begin
        exit('CAL-3527-SwitchItemTaxTable-20210827');
    end;
}