table 8062640 "CAGTX_Sales Doc. Tax Detail"
{

    DrillDownPageID = "CAGTX_Sales Doc. Tax Detail";
    LookupPageID = "CAGTX_Sales Doc. Tax Detail";

    fields
    {
        field(1; "Document Type"; enum "Sales Document Type")
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
            TableRelation = "Sales Header"."No." WHERE("Document Type" = FIELD("Document Type"));
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
        field(11; Description; Text[100])
        {
            CalcFormula = Lookup("Sales Line".Description WHERE("Document Type" = FIELD("Document Type"),
                                                                 "Document No." = FIELD("Document No."),
                                                                 "Line No." = FIELD("Line No.")));
            Caption = 'Description';
            FieldClass = FlowField;
        }
        field(15; Quantity; Decimal)
        {
            CalcFormula = Lookup("Sales Line".Quantity WHERE("Document Type" = FIELD("Document Type"),
                                                              "Document No." = FIELD("Document No."),
                                                              "Line No." = FIELD("Line No.")));
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;

            trigger OnValidate()
            var
            begin
            end;
        }
        field(16; "Outstanding Quantity"; Decimal)
        {
            CalcFormula = Lookup("Sales Line"."Outstanding Quantity" WHERE("Document Type" = FIELD("Document Type"),
                                                                            "Document No." = FIELD("Document No."),
                                                                            "Line No." = FIELD("Line No.")));
            Caption = 'Outstanding Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Qty. to Ship"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = Lookup("Sales Line"."Qty. to Ship" WHERE("Document Type" = FIELD("Document Type"),
                                                                    "Document No." = FIELD("Document No."),
                                                                    "Line No." = FIELD("Line No.")));
            Caption = 'Qty. to Ship';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;

            trigger OnValidate()
            var
            begin
            end;
        }
        field(27; "Line Discount %"; Decimal)
        {
            CalcFormula = Lookup("Sales Line"."Line Discount %" WHERE("Document Type" = FIELD("Document Type"),
                                                                       "Document No." = FIELD("Document No."),
                                                                       "Line No." = FIELD("Line No.")));
            Caption = 'Line Discount %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            MaxValue = 100;
            MinValue = 0;
        }
        field(28; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Lookup("Sales Line"."Line Discount Amount" WHERE("Document Type" = FIELD("Document Type"),
                                                                            "Document No." = FIELD("Document No."),
                                                                            "Line No." = FIELD("Line No.")));
            Caption = 'Line Discount Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Lookup("Sales Line"."Line Discount Amount" WHERE("Document Type" = FIELD("Document Type"),
                                                                            "Document No." = FIELD("Document No."),
                                                                            "Line No." = FIELD("Line No.")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Lookup("Sales Line"."Amount Including VAT" WHERE("Document Type" = FIELD("Document Type"),
                                                                            "Document No." = FIELD("Document No."),
                                                                            "Line No." = FIELD("Line No.")));
            Caption = 'Amount Including VAT';

            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Quantity Shipped"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = Lookup("Sales Line"."Quantity Shipped" WHERE("Document Type" = FIELD("Document Type"),
                                                                        "Document No." = FIELD("Document No."),
                                                                        "Line No." = FIELD("Line No.")));
            Caption = 'Quantity Shipped';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(69; "Inv. Discount Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Lookup("Sales Line"."Inv. Discount Amount" WHERE("Document Type" = FIELD("Document Type"),
                                                                            "Document No." = FIELD("Document No."),
                                                                            "Line No." = FIELD("Line No.")));
            Caption = 'Inv. Discount Amount';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(91; "Currency Code"; Code[10])
        {
            CalcFormula = Lookup("Sales Line"."Currency Code" WHERE("Document Type" = FIELD("Document Type"),
                                                                     "Document No." = FIELD("Document No."),
                                                                     "Line No." = FIELD("Line No.")));
            Caption = 'Currency Code';
            Editable = false;
            FieldClass = FlowField;
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
            Caption = 'Amount Tax Line';
            DataClassification = CustomerContent;
        }
        field(8062652; "Quantity Shipped Tax"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = Lookup("Sales Line"."Quantity Shipped" WHERE("Document Type" = FIELD("Document Type"),
                                                                        "Document No." = FIELD("Document No."),
                                                                        "Line No." = FIELD("Tax Line No.")));
            Caption = 'Quantity Shipped Tax';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(8062653; "Tax Amount. to Ship"; Decimal)
        {
            Caption = 'Tax Amount. to Ship';
            DataClassification = CustomerContent;
        }
        field(8062655; "Tax Type"; Enum "Sales Line Type")
        {
            CalcFormula = Lookup("Sales Line".Type WHERE("Document Type" = FIELD("Document Type"),
                                                          "Document No." = FIELD("Document No."),
                                                          "Line No." = FIELD("Tax Line No.")));
            Caption = 'Tax Type';
            FieldClass = FlowField;
        }
        field(8062656; "Tax No."; Code[20])
        {
            CalcFormula = Lookup("Sales Line"."No." WHERE("Document Type" = FIELD("Document Type"),
                                                           "Document No." = FIELD("Document No."),
                                                           "Line No." = FIELD("Tax Line No.")));
            Caption = 'Tax No.';
            FieldClass = FlowField;

            trigger OnValidate()
            var
            begin
            end;
        }
        field(8062657; "Tax Description"; Text[100])
        {
            CalcFormula = Lookup("Sales Line".Description WHERE("Document Type" = FIELD("Document Type"),
                                                                 "Document No." = FIELD("Document No."),
                                                                 "Line No." = FIELD("Tax Line No.")));
            Caption = 'Tax Description';
            FieldClass = FlowField;

            trigger OnValidate()
            var
            begin
            end;
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
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Tax Line No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = "Base Amount Tax", "Base Quantity Tax", "Amount Tax Line";
        }
    }

    fieldgroups
    {
    }
}

