codeunit 8062609 "CAGTX_AppAccessMgt"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::CAGSA_AppLicenseMgt, 'OnRegisterAppLicense', '', false, false)]
    local procedure OnRegisterAppLicence(var Sender: Codeunit CAGSA_AppLicenseMgt);
    begin
        AppLicenseMgt.RegisterAppLicense(GetAppID(), GetAppName());
    end;

    procedure IsAppAccessAllowed(DoSendNotification: Boolean): Boolean;
    begin
        exit(AppLicenseMgt.IsAppAccessAllowed(GetAppID(), GetAppName(), DoSendNotification));
    end;

    procedure MakeErrorMsgIfAppAccessNotAllowed();
    begin
        AppLicenseMgt.MakeErrorMsgIfAppAccessNotAllowed(GetAppID(), GetAppName());
    end;

    procedure SetAppDataInIsolatedStorageOnInstall();
    begin
        AppLicenseMgt.SetAppDataInIsolatedStorageOnInstall(GetAppID());
    end;

    procedure GetAppID(): Guid;
    var
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        exit(FORMAT(AppInfo.Id()));
    end;

    procedure GetAppName(): Text;
    var
        CAGPCAppNameTxt: Label 'Tax Management';
    begin
        exit(CAGPCAppNameTxt);
    end;

    var
        AppLicenseMgt: Codeunit CAGSA_AppLicenseMgt;

}
