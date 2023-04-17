table 8062639 "CAGTX_Customer Subject To Tax"
{

    Caption = 'Customer Subject To Tax';
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
        field(3; "Invoiced Tax"; Boolean)
        {
            Caption = 'Invoiced Tax';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            DataClassification = CustomerContent;
            OptionCaption = 'Third Party,Posting Group,All';
            OptionMembers = "Third Party","Posting Group",All;
        }
        field(5; "Link to Table"; Option)
        {
            Caption = 'Link to Table';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Customer,Vendor';
            OptionMembers = " ",Customer,Vendor;
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
        if "Invoiced Tax" then
            Error(MustDeleteErr);
    end;

    var
        MustDeleteErr: Label 'You must delete then associated Tax Charged to customer';
}

