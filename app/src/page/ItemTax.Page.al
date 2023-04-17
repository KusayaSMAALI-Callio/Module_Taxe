page 8062636 "CAGTX_Item Tax"
{

    Caption = 'Assign Tax To Items';
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "CAGTX_Item Tax V2";

    layout
    {
        area(content)
        {
            field("UnSynchronizeRateType_G"; UnSynchronizeRateType_G)
            {
                Caption = 'UnSynchronize Rate Type';
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the value of the UnSynchronize Rate Type field';
            }
            repeater(Group)
            {
                FreezeColumn = Description;
                field("Tax Code"; Rec."Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Tax Code field';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Description field';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Type field';

                    trigger OnValidate()
                    begin
                        EditableItemAttribute_G := (Rec.Type = Rec.Type::Item);
                    end;
                }
                field("No."; Rec."No.")
                {
                    ShowMandatory = NOT EditableItemAttribute_G;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the No. field';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    Editable = EditableItemAttribute_G;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Variant Code field';
                }
                field("Item Category Code"; Rec."Item Category Code")
                {
                    Editable = EditableItemAttribute_G;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Item Category Code field';
                }
                field("Effective Date"; Rec."Effective Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Effective Date field';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Unit of Measure Code field';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Minimum Quantity field';
                }
                field("Rate Type"; Rec."Rate Type")
                {
                    Editable = UnSynchronizeRateType_G;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Rate Type field';
                }
                field("Rate Value"; Rec."Rate Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Value field';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        EditableItemAttribute_G := (Rec.Type = Rec.Type::Item);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        CMBTax_L: Record CAGTX_Tax;
    begin
        Rec.CalcFields(Description);
        if CMBTax_L.Get(Rec."Tax Code") then begin
            Rec."Rate Type" := CMBTax_L."Default Rate Type";
            Rec."Rate Value" := CMBTax_L."Default Rate Value";
        end;

        if (Rec.Type = Rec.Type::Item) and (FromItemNo <> '') then
            Rec."No." := FromItemNo;
    end;

    var
        [InDataSet]
        EditableItemAttribute_G: Boolean;
        UnSynchronizeRateType_G: Boolean;

        FromItemNo: code[20];



    procedure SetFromItemNo(CurrentItemNo: Code[20])
    begin
        FromItemNo := CurrentItemNo;
    end;
}