tableextension 8062618 "CAGTX_Service Line" extends "Service Line"
{
    fields
    {
        field(8062635; "CAGTX_Tax Code"; Code[20])
        {
            Caption = 'Tax Code';
            DataClassification = CustomerContent;
            TableRelation = CAGTX_Tax;
        }
        field(8062636; "CAGTX_Tax Line"; Boolean)
        {
            Caption = 'Tax Line';
            DataClassification = CustomerContent;
        }
        field(8062637; "CAGTX_Origin Tax Line"; Integer)
        {
            Caption = 'Origin Tax Line';
            DataClassification = CustomerContent;
        }
        field(8062638; "CAGTX_Hide Tax Line"; Boolean)
        {
            Caption = 'Hide Tax Line';
            DataClassification = CustomerContent;
        }
        field(8062639; "CAGTX_Tax Amount"; Decimal)
        {
            BlankZero = true;
            CalcFormula = Sum("CAGTX_Service Doc. Tax Detail"."Amount Tax Line" WHERE("Document Type" = FIELD("Document Type"),
                                                                                       "Document No." = FIELD("Document No."),
                                                                                       "Line No." = FIELD("Line No."),
                                                                                       "Rate Type" = FILTER(<> "Flat Rate")));
            Caption = 'Amount  Tax';
            FieldClass = FlowField;
        }
    }
    keys
    {
        key(Key1; "CAGTX_Tax Line", "CAGTX_Tax Code", "CAGTX_Origin Tax Line")
        {
        }
    }
}

