table 8062636 "CAGTX_Item Tax V2"
{

    Caption = 'Item Tax';
    DataClassification = CustomerContent;
    DrillDownPageID = "CAGTX_Item Tax";
    LookupPageID = "CAGTX_Item Tax";

    fields
    {
        field(1; "Tax Code"; Code[20])
        {
            Caption = 'Tax Code';
            DataClassification = CustomerContent;
            TableRelation = CAGTX_Tax;

            trigger OnValidate()
            begin
                Rec.CalcFields(Description);
            end;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
            TableRelation = IF (Type = CONST(Item)) Item
            ELSE
            IF (Type = CONST(Resource)) Resource
            ELSE
            IF (Type = CONST("G/L Account")) "G/L Account";
        }
        field(3; "Rate Type"; Option)
        {
            Caption = 'Rate Type';
            DataClassification = CustomerContent;
            Editable = false;
            OptionCaption = 'Unit Amount,Percent,Flat Rate';
            OptionMembers = "Unit Amount",Percent,"Flat Rate";

            trigger OnValidate()
            begin
                CheckCalculType(Rec);
            end;
        }
        field(4; "Rate Value"; Decimal)
        {
            Caption = 'Value';
            DataClassification = CustomerContent;
        }
        field(5; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            DataClassification = CustomerContent;
            TableRelation = IF (Type = CONST(Item)) "Item Category".Code;

            trigger OnValidate()
            begin
                if ("Item Category Code" <> '') then begin
                    TestField(Type, Type::Item);
                    TestField("No.", '');
                end
            end;
        }
        field(6; "Product Group Code"; Code[10])
        {
            Caption = 'Product Group Code';
            DataClassification = CustomerContent;
        }
        field(7; Type; Option)
        {
            Caption = 'Type';
            DataClassification = CustomerContent;
            OptionCaption = ',G/L Account,Item,Resource';
            OptionMembers = " ","G/L Account",Item,Resource;

            trigger OnValidate()
            begin
                if (Type <> xRec.Type) then begin
                    "No." := '';
                    "Item Category Code" := '';
                    "Variant Code" := '';
                    "Unit of Measure Code" := '';
                    "Minimum Quantity" := 0;
                    "Effective Date" := 0D;
                end;
            end;
        }
        field(8; "Effective Date"; Date)
        {
            Caption = 'Effective Date';
            DataClassification = CustomerContent;
        }
        field(9; Description; Text[100])
        {
            CalcFormula = Lookup(CAGTX_Tax.Description WHERE(Code = FIELD("Tax Code")));
            Caption = 'Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Minimum Quantity"; Decimal)
        {
            Caption = 'Minimum Quantity';
            DataClassification = CustomerContent;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField("Unit of Measure Code");
            end;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = CustomerContent;
            TableRelation = IF (Type = CONST(Item),
                                "No." = FILTER(<> '')) "Item Unit of Measure".Code WHERE("Item No." = FIELD("No."))
            ELSE
            IF (Type = CONST(Resource),
                                         "No." = FILTER(<> '')) "Resource Unit of Measure".Code WHERE("Resource No." = FIELD("No."))
            ELSE
            "Unit of Measure";
        }
        field(5700; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = CustomerContent;
            TableRelation = IF (Type = CONST(Item)) "Item Variant".Code WHERE("Item No." = FIELD("No."));
        }
    }

    keys
    {
        key(Key1; Type, "Tax Code", "No.", "Item Category Code", "Product Group Code", "Variant Code", "Effective Date", "Unit of Measure Code", "Minimum Quantity")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if (Type in [Type::"G/L Account", Type::Resource]) or ("Unit of Measure Code" <> '') then
            TestField("No.");
    end;

    trigger OnRename()
    begin
        if (Type in [Type::"G/L Account", Type::Resource]) or ("Unit of Measure Code" <> '') then
            TestField("No.");
    end;

    var
        CalculTypeErr: Label 'You can not set the "type value" with the value %1 because the tax use a "posted option" equal to %2.', Comment = '%1 = value ; %2 = value';

    local procedure CheckCalculType(p_Rec: Record "CAGTX_Item Tax V2")
    var
        CMBTax_L: Record CAGTX_Tax;
    begin
        if p_Rec."Rate Type" = p_Rec."Rate Type"::"Flat Rate" then begin
            CMBTax_L.Get(p_Rec."Tax Code");
            if CMBTax_L."Posted Option" = CMBTax_L."Posted Option"::Prorata then
                Error(CalculTypeErr, p_Rec."Rate Type", CMBTax_L."Posted Option");
        end;
    end;
}

