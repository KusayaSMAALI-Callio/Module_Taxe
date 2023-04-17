codeunit 50252 "CAGTX_TechnicalTestsHelper"
{
    procedure TestTransferfields(FromTableID: Integer; ToTableID: Integer)
    var
        FromField: Record field;
        ToField: Record field;
    begin
        ToField.reset();
        ToField.SetRange(TableNo, ToTableID);
        if ToField.findset() then
            repeat
                if FromField.get(FromTableID, ToField."No.") then
                    if NOT AreFieldsMatching(FromField, ToField) then
                        error('Field %1 of table %2 (%3 %4) may not be transfered to Field %5 of table %6 (%7 %8)',
                                FromField."No.", FromField.TableNo, FromField.Type, FromField.Len,
                                ToField."No.", ToField.TableNo, ToField.Type, ToField.Len);
            until ToField.next() = 0;
    end;

    procedure TestTableRelations(FromID: Integer; ToID: Integer)
    var
        TableRelMetadata: record "Table Relations Metadata";
    begin
        // Testing App Tables
        TableRelMetadata.Reset();
        TableRelMetadata.SetRange("Table ID", FromID, ToID);
        TestTableRelMetadataTableRelations(TableRelMetadata);

        // Testing App Fields
        TableRelMetadata.Reset();
        TableRelMetadata.SetRange("Field No.", FromID, ToID);
        TestTableRelMetadataTableRelations(TableRelMetadata);
    end;

    local procedure TestTableRelMetadataTableRelations(var TableRelMetadata: record "Table Relations Metadata")
    var
        FromField: Record field;
        ToField: Record field;
    begin
        if TableRelMetadata.findset() then
            repeat
                ToField.get(TableRelMetadata."Table ID", TableRelMetadata."Field No.");
                FromField.get(TableRelMetadata."Related Table ID", TableRelMetadata."Related Field No.");
                if NOT AreFieldsMatching(FromField, ToField) then
                    error('Table Relation From Field %1 of table %2 (%3 %4) to Field %5 of table %6 (%7 %8) may lead to Overflow.',
                            FromField."No.", FromField.TableNo, FromField.Type, FromField.Len,
                            ToField."No.", ToField.TableNo, ToField.Type, ToField.Len);
            until TableRelMetadata.next() = 0;
    end;

    local procedure AreFieldsMatching(FromField: Record Field; ToField: Record Field): Boolean;
    begin
        exit(((FromField.Type = ToField.Type) or ((FromField.Type = FromField.Type::Code) and (ToField.Type = ToField.Type::Text))) and (FromField.Len <= ToField.Len));
    end;
}

