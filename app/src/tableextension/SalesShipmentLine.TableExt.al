tableextension 8062607 "CAGTX_Sales Shipment Line" extends "Sales Shipment Line"
{
    fields
    {
        field(8062635; "CAGTX_Tax Code"; Code[20])
        {
            Caption = 'Tax Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = CAGTX_Tax;
        }
        field(8062636; "CAGTX_Tax Line"; Boolean)
        {
            Caption = 'Tax Line';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(8062637; "CAGTX_Origin Tax Line"; Integer)
        {
            Caption = 'Origin Tax Line';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(8062638; "CAGTX_Hide Tax Line"; Boolean)
        {
            Caption = 'Hide Tax Line';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

