table 8062635 "CAGTX_Tax"
{

    Caption = 'Taxes';
    DataClassification = CustomerContent;
    DrillDownPageID = CAGTX_Taxes;
    LookupPageID = CAGTX_Taxes;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(3; "Default Rate Type"; Option)
        {
            Caption = 'Rate Type';
            DataClassification = CustomerContent;
            OptionCaption = 'Unit Amount,Percent,Flat Rate';
            OptionMembers = "Unit Amount",Percent,"Flat Rate";
        }
        field(4; "Default Rate Value"; Decimal)
        {
            Caption = 'Value';
            DataClassification = CustomerContent;
        }
        field(10; "Show on Order Line"; Boolean)
        {
            Caption = 'Show on Order Line';
            DataClassification = CustomerContent;
            InitValue = true;

            trigger OnValidate()
            begin
                if not CheckTaxSalesLine() then
                    UpdatesTaxSalesLine();
            end;
        }
        field(11; "Show on Ship. Line"; Boolean)
        {
            Caption = 'Show on Ship. Line';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(12; "Show Line"; Boolean)
        {
            Caption = 'Show Line';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(15; "Posted Option"; Option)
        {
            Caption = 'Posted Option';
            DataClassification = CustomerContent;
            OptionCaption = 'First,Prorata,Last';
            OptionMembers = First,Prorata,Last;

            trigger OnValidate()
            begin
                CheckPostedOption(Rec, FieldNo("Posted Option"));
            end;
        }
        field(16; "Applied Option"; Option)
        {
            Caption = 'Applied Option';
            DataClassification = CustomerContent;
            OptionCaption = 'Posting Date,Document Date,Order Date';
            OptionMembers = "Posting Date","Document Date","Order Date";
        }
        field(20; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(21; "Allow Line Disc."; Boolean)
        {
            Caption = 'Applied on Amount Incl. Discount';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(25; "Calcul Type"; Option)
        {
            Caption = 'Calcul Type';
            DataClassification = CustomerContent;
            OptionCaption = 'Line,Total';
            OptionMembers = Line,Total;

            trigger OnValidate()
            begin
                CheckPostedOption(Rec, FieldNo("Calcul Type"));
            end;
        }
        field(26; "Tax Paid By The Company"; Boolean)
        {
            Caption = 'Tax Paid By The Company';
            DataClassification = CustomerContent;
        }
        field(27; "Tax Apply on VAT"; Boolean)
        {
            Caption = 'Tax Apply on VAT Price';
            DataClassification = CustomerContent;
        }
        field(40; "Sale Account Type"; Option)
        {
            Caption = 'Sale Account Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,G/L Account,,Resource,,Charge (Item)';
            OptionMembers = " ","G/L Account",,Resource,,"Charge (Item)";

            trigger OnLookup()
            begin
                CheckPostedOption(Rec, FieldNo("Sale Account Type"));
            end;
        }
        field(41; "Sale Account No."; Code[20])
        {
            Caption = 'Sale Account No.';
            DataClassification = CustomerContent;
            TableRelation = IF ("Sale Account Type" = CONST(Resource)) Resource."No."
            ELSE
            IF ("Sale Account Type" = CONST("G/L Account")) "G/L Account"."No."
            ELSE
            IF ("Sale Account Type" = CONST("Charge (Item)")) "Item Charge"."No.";
        }
        field(50; "Purch. Account Type"; Option)
        {
            Caption = 'Purchase Account Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,G/L Account,,,,Charge (Item)';
            OptionMembers = "  ","G/L Account",,Resource,,"Charge (Item)";

            trigger OnValidate()
            begin
                CheckPostedOption(Rec, FieldNo("Purch. Account Type"));
            end;
        }
        field(51; "Purch. Account No."; Code[20])
        {
            Caption = 'Purchase Account No.';
            DataClassification = CustomerContent;
            TableRelation = IF ("Purch. Account Type" = CONST(Resource)) Resource."No."
            ELSE
            IF ("Purch. Account Type" = CONST("G/L Account")) "G/L Account"."No."
            ELSE
            IF ("Purch. Account Type" = CONST("Charge (Item)")) "Item Charge"."No.";
        }
        field(60; "Service Account Type"; Option)
        {
            Caption = 'Service Account Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,,Resource,,G/L Account';
            OptionMembers = " ",,Resource,,"G/L Account";
        }
        field(61; "Service Account No."; Code[20])
        {
            Caption = 'Service Account No.';
            DataClassification = CustomerContent;
            TableRelation = IF ("Service Account Type" = CONST(Resource)) Resource."No."
            ELSE
            IF ("Service Account Type" = CONST("G/L Account")) "G/L Account"."No.";
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }

    trigger OnDelete()
    var
        CMBItemTax_L: Record "CAGTX_Item Tax V2";
        CMBTaxChargedThridParty_L: Record "CAGTX_Tax Assign. Third Party";
    begin
        CMBItemTax_L.SetRange("Tax Code", Code);
        CMBItemTax_L.DeleteAll();
        CMBTaxChargedThridParty_L.SetRange("Tax Code", Code);
        CMBTaxChargedThridParty_L.DeleteAll();
    end;

    trigger OnInsert()
    begin
        UpdateTaxAssignment(Rec);
    end;

    trigger OnModify()
    begin
        UpdateTaxAssignment(Rec);
    end;

    var
        WarningMsg: Label 'This change may take some minutes, do you wish to continue ?';
        ConfirmUpdQst: Label 'You changed the default, \do you want to initialize your assignment item lines';
        PostedOptionErr: Label 'Incompatible Setting.\You can not set the posted option to "%1" with the calcul type "%2".', Comment = '%1 = posted option ; %2 = calcul type';
        PostedOptionErrorChargeItemErr: Label 'Incompatible Setting.\You can not set the posted option to "%1" with the calcul type "%2" associed with "Charge (Item)"', Comment = '%1 = posted option ; %2 = calcul type';

    procedure UpdatesTaxSalesLine()
    var
        SalesLines_L: Record "Sales Line";
    begin
        SalesLines_L.Reset();
        SalesLines_L.SetCurrentKey("CAGTX_Tax Line", "CAGTX_Tax Code", "CAGTX_Origin Tax Line");
        SalesLines_L.SetRange("CAGTX_Tax Line", true);
        SalesLines_L.SetRange("CAGTX_Hide Tax Line", "Show on Order Line");
        SalesLines_L.SetRange("CAGTX_Tax Code", Code);
        if not SalesLines_L.IsEmpty() then
            if Confirm(WarningMsg, false) then
                SalesLines_L.ModifyAll("CAGTX_Hide Tax Line", not "Show on Order Line");
    end;

    procedure CheckTaxSalesLine(): Boolean
    var
        SalesLines_L: Record "Sales Line";
    begin
        SalesLines_L.Reset();
        SalesLines_L.SetCurrentKey("CAGTX_Tax Line", "CAGTX_Tax Code", "CAGTX_Origin Tax Line");
        SalesLines_L.SetRange("CAGTX_Tax Line", true);
        SalesLines_L.SetRange("CAGTX_Tax Code", Code);
        SalesLines_L.SetRange("CAGTX_Hide Tax Line", "Show on Order Line");
        exit(SalesLines_L.IsEmpty());
    end;

    local procedure UpdateTaxAssignment(p_Rec: Record CAGTX_Tax)
    var
        CMBItemTax_L: Record "CAGTX_Item Tax V2";
        ConfirmDlg_L: Boolean;
    begin
        if ("Default Rate Type" <> xRec."Default Rate Type") or
           ("Default Rate Value" <> xRec."Default Rate Value") then begin
            CMBItemTax_L.SetRange("Tax Code", p_Rec.Code);
            if not CMBItemTax_L.IsEmpty then begin
                ConfirmDlg_L := not GuiAllowed and (("Default Rate Value" <> 0) or ("Default Rate Type" <> xRec."Default Rate Type"));
                if not ConfirmDlg_L and (("Default Rate Value" <> 0) or ("Default Rate Type" <> xRec."Default Rate Type")) then
                    ConfirmDlg_L := Confirm(ConfirmUpdQst, true);
                if ConfirmDlg_L then begin
                    if ("Default Rate Value" <> 0) then
                        CMBItemTax_L.ModifyAll("Rate Value", p_Rec."Default Rate Value", true);
                    if ("Default Rate Type" <> xRec."Default Rate Type") then
                        CMBItemTax_L.ModifyAll("Rate Type", p_Rec."Default Rate Type", true);
                end;
            end;
        end;
    end;

    local procedure CheckPostedOption(p_Rec: Record CAGTX_Tax; p_FieldNo: Integer)
    begin
        if (p_FieldNo = FieldNo("Calcul Type")) then begin
            if (p_Rec."Posted Option" = p_Rec."Posted Option"::Prorata) and (p_Rec."Calcul Type" = p_Rec."Calcul Type"::Total) then
                Error(PostedOptionErr, p_Rec."Posted Option"::Prorata, p_Rec."Calcul Type"::Total);
        end else
            if (p_Rec."Posted Option" = p_Rec."Posted Option"::Prorata) then
                p_Rec.TestField("Calcul Type", p_Rec."Calcul Type"::Line);

        if (p_Rec."Posted Option" = p_Rec."Posted Option"::Last) and (p_Rec."Calcul Type" = p_Rec."Calcul Type"::Total) and
            ((p_Rec."Sale Account Type" = p_Rec."Sale Account Type"::"Charge (Item)") or (p_Rec."Purch. Account Type" = p_Rec."Purch. Account Type"::"Charge (Item)")) then
            Error(PostedOptionErrorChargeItemErr, p_Rec."Posted Option", p_Rec."Calcul Type"::Total);
    end;
}

