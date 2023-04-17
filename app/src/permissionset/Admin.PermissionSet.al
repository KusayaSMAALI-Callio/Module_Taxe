permissionset 8062606 "CAGTX_Admin"
{
    Assignable = true;
    Caption = 'Tax Management - Admin', MaxLength = 30;
    Permissions =
        table "CAGTX_Customer Subject To Tax" = X,
        tabledata "CAGTX_Customer Subject To Tax" = RMID,
        table CAGTX_Tax = X,
        tabledata CAGTX_Tax = RMID,
        table "CAGTX_Tax Assign. Third Party" = X,
        tabledata "CAGTX_Tax Assign. Third Party" = RMID,
        table "CAGTX_Item Tax V2" = X,
        tabledata "CAGTX_Item Tax V2" = RMID,
        table "CAGTX_Purch. Doc. Tax Detail" = X,
        tabledata "CAGTX_Purch. Doc. Tax Detail" = RMID,
        table "CAGTX_Service Doc. Tax Detail" = X,
        tabledata "CAGTX_Service Doc. Tax Detail" = RMID,
        table "CAGTX_Sales Doc. Tax Detail" = X,
        tabledata "CAGTX_Sales Doc. Tax Detail" = RMID,
        table "CAGTX_Doc. Tax Buffer" = X,
        tabledata "CAGTX_Doc. Tax Buffer" = RMID,
        codeunit CAGTX_AppAccessMgt = X,
        codeunit CAGTX_Install = X,
        codeunit "CAGTX_Upgrade Tag Definitions" = X,
        codeunit "CAGTX_Tax Subscription" = X,
        codeunit "CAGTX_Purch. Tax Management" = X,
        codeunit CAGTX_Upgrade = X,
        codeunit "CAGTX_Tax Management" = X,
        codeunit "CAGTX_Service Tax Management" = X,
        codeunit "CAGTX_Sales Tax Management" = X,
        page "CAGTX_Purch. Cr.Memo Tax Lines" = X,
        page "CAGTX_Purch. Doc. Tax Detail" = X,
        page "CAGTX_Purch Doc Tax Lines" = X,
        page "CAGTX_Purch Invoice Tax Lines" = X,
        page "CAGTX_Receive Tax Lines" = X,
        page "CAGTX_Sales Cr. Memo Tax Lines" = X,
        page "CAGTX_Sales Doc. Tax Detail" = X,
        page "CAGTX_Sales Invoice Tax Lines" = X,
        page "CAGTX_Sales Rt. Rec. Tax Lines" = X,
        page "CAGTX_Serv. Cr.Memo Tax Lines" = X,
        page "CAGTX_Service Doc. Tax Detail" = X,
        page "CAGTX_Service Doc Tax Lines" = X,
        page "CAGTX_Serv. Invoice Tax Lines" = X,
        page "CAGTX_Shipment Tax Lines" = X,
        page CAGTX_Tax = X,
        page "CAGTX_Tax Assgn. to Third Part" = X,
        page CAGTX_Taxes = X,
        page "CAGTX_Tax Lines" = X,
        page "CAGTX_Third Party Subj. To Ta" = X,
        page "CAGTX_Item Taxes SP" = X,
        page "CAGTX_Item Tax" = X,
        page "CAGTX_Sales Doc Tax Lines" = X,
        query "CAGTX_Purch Ord. Frst Inv Date" = X,
        query "CAGTX_Purch Ret. Frst Cr. Date" = X,
        query "CAGTX_Purch Tax Line Chk View" = X,
        query "CAGTX_Sales Ord. Frst Inv Date" = X,
        query "CAGTX_Sales Ret. Frst Cr. Date" = X,
        query "CAGTX_Sales Tax Line Chk View" = X,
        query "CAGTX_Serv. Ord. Frst Inv Date" = X,
        codeunit "CAGTX_Transfer tax Lines" = X;
}
