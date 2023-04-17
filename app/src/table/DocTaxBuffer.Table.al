table 8062645 "CAGTX_Doc. Tax Buffer"
{

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(5; Type; Option)
        {
            Caption = 'Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,G/L Account,Item,Resource,Fixed Asset,Charge (Item)';
            OptionMembers = " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)";
        }
        field(6; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
            begin
            end;
        }
        field(11; Description; Text[50])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(13; "Amount Rounding Precision"; Decimal)
        {
            Caption = 'Amount Rounding Precision';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 5;
            InitValue = 0.01;
            MinValue = 0;
        }
        field(14; "Unit-Amount Rounding Precision"; Decimal)
        {
            Caption = 'Unit-Amount Rounding Precision';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 9;
            InitValue = 0.00001;
            MinValue = 0;
        }
        field(22; "Unit Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';
            DataClassification = CustomerContent;
        }
        field(25; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(27; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(33; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;
        }
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
            DataClassification = CustomerContent;
        }
        field(91; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = Currency;
        }
        field(1300; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = CustomerContent;
            TableRelation = IF (Type = CONST(Item)) "Item Variant".Code WHERE("Item No." = FIELD("No."));
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
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

            trigger OnValidate()
            var
            begin
            end;
        }
        field(5415; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(5416; "Outstanding Qty. (Base)"; Decimal)
        {
            Caption = 'Outstanding Qty. (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5417; "Qty. to Ship"; Decimal)
        {
            Caption = 'Qty. to Ship';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5418; "Qty. to Receive"; Decimal)
        {
            Caption = 'Qty. to Receive';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5709; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            DataClassification = CustomerContent;
            TableRelation = "Item Category";
        }
        field(5712; "Product Group Code"; Code[10])
        {
            Caption = 'Product Group Code';
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'Product Group is removed from standard.';
        }
        field(8062635; "Tax Code"; Code[20])
        {
            Caption = 'Tax Code';
            DataClassification = CustomerContent;
            TableRelation = CAGTX_Tax;
        }
        field(8062637; "Tax Line No."; Integer)
        {
            Caption = 'Tax Line No.';
            DataClassification = CustomerContent;
        }
        field(8062638; "Base Quantity Tax"; Decimal)
        {
            Caption = 'Base Quantity Tax Line';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(8062639; "Base Amount Tax"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            Caption = 'Base Amount Tax Line';
            DataClassification = CustomerContent;
        }
        field(8062640; "Rate value"; Decimal)
        {
            Caption = 'Rate Value';
            DataClassification = CustomerContent;
        }
        field(8062641; "Rate Type"; Option)
        {
            Caption = 'Rate Type ';
            DataClassification = CustomerContent;
            OptionCaption = 'Unit Amount,Percent,Flat Rate';
            OptionMembers = "Unit Amount",Percent,"Flat Rate";
        }
        field(8062642; "Calcul Type"; Option)
        {
            Caption = 'Calcul Type';
            DataClassification = CustomerContent;
            OptionCaption = 'Line,Total';
            OptionMembers = Line,Total;
        }
        field(8062650; "Quantity Tax Line"; Decimal)
        {
            Caption = 'Quantity Tax Line';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(8062651; "Amount Tax Line"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            Caption = 'Amount Tax Line (LCY)';
            DataClassification = CustomerContent;
        }
        field(8062652; "Tax Unit Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Tax Unit Amount';
            DataClassification = CustomerContent;
        }
        field(8062653; "Tax VAT %"; Decimal)
        {
            Caption = 'VAT Tax %';
            DataClassification = CustomerContent;
        }
        field(8062654; "Tax Account Type"; Option)
        {
            Caption = 'Sale Account Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,G/L Account,,Resource,,Charge (Item)';
            OptionMembers = " ","G/L Account",,Resource,,"Charge (Item)";
        }
        field(8062655; "Tax Account No."; Code[20])
        {
            Caption = 'Sale Account No.';
            DataClassification = CustomerContent;
        }
        field(8062660; "Application Order"; Integer)
        {
            Caption = 'Application Order';
            DataClassification = CustomerContent;
            InitValue = 1;
            MinValue = 0;
        }
        field(8062661; "Calculate Tax on Tax"; Boolean)
        {
            Caption = 'Calculate Tax on Tax';
            DataClassification = CustomerContent;
        }
        field(8062670; "Intial Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }
        field(8062680; "Table No."; Integer)
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Line No.", "Tax Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

