codeunit 50255 "CAGTX_Permission Test Mgt"
{
    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    procedure SetO365BusinessPremiumPermissions()
    begin
        LibraryLowerPermissions.SetO365BusinessPremium();
        LibraryLowerPermissions.AddPermissionSet('CAGTX_Admin');
    end;

    procedure SetO365BusinessEssentialPermissions()
    begin
        LibraryLowerPermissions.SetO365BusFull();
        LibraryLowerPermissions.AddPermissionSet('CAGTX_Admin');
    end;
}