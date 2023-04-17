table 8062638 "CAGTX_Tax Assign. Third Party"
{

    Caption = 'Tax Assignment To Third Party';
    DataClassification = CustomerContent;
    DrillDownPageID = "CAGTX_Tax Assgn. to Third Part";
    LookupPageID = "CAGTX_Tax Assgn. to Third Part";

    fields
    {
        field(1; "Tax Code"; Code[20])
        {
            Caption = 'Tax Code';
            DataClassification = CustomerContent;
            TableRelation = CAGTX_Tax;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
            TableRelation = IF (Type = CONST("Third Party"),
                                "Link to Table" = CONST(Customer)) Customer."No."
            ELSE
            IF (Type = CONST("Third Party"),
                                         "Link to Table" = CONST(Vendor)) Vendor."No."
            ELSE
            IF (Type = CONST("Posting Group"),
                                                  "Link to Table" = CONST(Customer)) "Customer Posting Group".Code
            ELSE
            IF (Type = CONST("Posting Group"),
                                                           "Link to Table" = CONST(Vendor)) "Vendor Posting Group".Code;
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            DataClassification = CustomerContent;
            OptionCaption = 'Third Party,Posting Group,All';
            OptionMembers = "Third Party","Posting Group",All;

            trigger OnValidate()
            begin
                if Type <> xRec.Type then
                    "No." := '';
            end;
        }
        field(4; "Link to Table"; Option)
        {
            Caption = 'Link to Table';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Customer,Vendor';
            OptionMembers = " ",Customer,Vendor;
            ValuesAllowed = Customer, Vendor;
        }
        field(10; "Post. Group Filter"; Code[10])
        {
            Caption = 'Customer Posting Group Filter';
            FieldClass = FlowFilter;
        }
        field(11; "Is in Customer Posting Gp."; Boolean)
        {
            CalcFormula = Exist(Customer WHERE("Customer Posting Group" = FIELD("Post. Group Filter"),
                                                "No." = FIELD(FILTER("No."))));
            Caption = 'Is in Cust. Posting Gp.';
            FieldClass = FlowField;
        }
        field(12; "Is in Vendor Posting Gp."; Boolean)
        {
            CalcFormula = Exist(Vendor WHERE("Vendor Posting Group" = FIELD("Post. Group Filter"),
                                              "No." = FIELD(FILTER("No."))));
            Caption = 'Is in Vendor Posting Gp.';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Tax Code", "Link to Table", Type, "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CMBTaxManagement_G.UpdateThridPartySubjectToTax(Rec, xRec, true, false);
    end;

    trigger OnInsert()
    begin
        CMBTaxManagement_G.UpdateThridPartySubjectToTax(Rec, xRec, false, false);
    end;

    trigger OnRename()
    begin
        CMBTaxManagement_G.UpdateThridPartySubjectToTax(Rec, xRec, false, true);
    end;

    var
        CMBTaxManagement_G: Codeunit "CAGTX_Tax Management";
}

