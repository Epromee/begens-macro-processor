
/*

    BEGENS (BEyond GENeric Sql) macroprocessor for MS SQL Server T-SQL;
    
    Version:
        Begens macro processor 0.1
    Author:
        Egor Promyshlennikov
    Date:
        21 February 2021
    Contacts:
        https://github.com/Epromee
        https://vk.com/epromee
    
    The code is provided "as is", no warranty, no responsibility and all that stuff.
    Brand new license's gonna be added later.
    
*/

/* Cool big brain procedure to make my SQL code even more badass */
create procedure begens

    /* Use these variables: */
    @raw_code nvarchar(max) output, -- flush your kickass Begens code here
    @just_translate bit = null, -- set 1 if you want your code to be shown instead of being executed
    
    /* Never use these variables: */
    @index int = null output,
    @processed_code nvarchar(max) = null output,
    @node_type int = null
as
begin

    set nocount on;
    set xact_abort on;
    
    /* TODO's
        -- make multiple variable declaration
        -- strict code inlining in the beginning
        -- macro variables
        -- checkout unclosed parenthesis in non-parent nodes
        -- process dummy parenthesis { as no operation
        -- don't emplace #t table if no $${} parenthesis was envolved
    */
    
    /* User called the procedure */
    if @index is null
    begin

        /* Track how many vars we have used throughout the whole recursive script */
        create table #used_variables(vcnt bigint);
        insert into #used_variables values(0);

        /* For pushing-up recursive call returns */
        create table #pushup_output(str nvarchar(max));

        /* Go ahead */

        declare @my_processed_code nvarchar(max) = '';
        declare @my_index int = 1;

        set @my_processed_code = @my_processed_code + 'declare @qraw varchar(10) = '''''''';' + char(13) + char(10);
        set @my_processed_code = @my_processed_code + 'declare @qrep varchar(10) = '''''''''''';' + char(13) + char(10);
        set @my_processed_code = @my_processed_code + 'declare @dy nvarchar(max);' + char(13) + char(10);
        set @my_processed_code = @my_processed_code + 'create table #t(id bigint identity(1, 1) unique clustered, t nvarchar(max));' + char(13) + char(10);

        exec begens @raw_code output, 0, @my_index output, @my_processed_code output, 0;

        set @my_processed_code = @my_processed_code + 'drop table #t;' + char(13) + char(10);
        set @my_processed_code = @my_processed_code + 'exec(@main);' + char(13) + char(10);

        if (@just_translate = 1)
        begin
            select @my_processed_code as BegensOutput;
        end
        else begin
            exec(@my_processed_code);
        end;
        
    end
    
    /* System called the procedure*/
    else begin
    
        /*
            node_type:
            0 - core input
            1 - quote
            2 - pre-evaluated subquery

        */

        declare @prepared_code nvarchar(max) = '';

        while @index <= len(@raw_code) and (substring(@raw_code, @index, 1) != '}' or @node_type = 0)
        begin

            declare @code_lookahead nvarchar(3) = substring(@raw_code, @index, 3);

            declare @yet_another_variable nvarchar(10);
            declare @previous_output nvarchar(max);

            if @code_lookahead = '$${'
            begin
                set @index = @index + 3;
                exec begens @raw_code output, 0, @index output, @processed_code output, 2;

                set @yet_another_variable = '@v' + cast((select top 1 vcnt from #used_variables) as nvarchar(10));
                update #used_variables set vcnt = vcnt + 1;

                set @previous_output = (select str from #pushup_output);
                truncate table #pushup_output;

                set @processed_code = @processed_code + 'set @dy=''' + @previous_output + ''';' + char(13) + char(10);
                set @processed_code = @processed_code + 'declare ' + @yet_another_variable + ' nvarchar(max) = '''';' + char(13) + char(10);
                set @processed_code = @processed_code + 'insert into #t(t) exec(@dy);' + char(13) + char(10)
                set @processed_code = @processed_code + 'select ' + @yet_another_variable + ' = ' + @yet_another_variable + ' + t from #t order by id;' + char(13) + char(10);
                set @processed_code = @processed_code + 'truncate table #t;' + char(13) + char(10);

                set @prepared_code = @prepared_code + '''+' + @yet_another_variable + '+''';

            end
            else if @code_lookahead = '@@{'
            begin
                set @index = @index + 3;
                exec begens @raw_code output, 0, @index output, @processed_code output, 1;

                set @yet_another_variable = '@v' + cast((select top 1 vcnt from #used_variables) as nvarchar(10));
                update #used_variables set vcnt = vcnt + 1;

                set @previous_output = (select str from #pushup_output);
                truncate table #pushup_output;

                set @processed_code = @processed_code + 'declare ' + @yet_another_variable + ' nvarchar(max)=''' + @previous_output + ''';' + char(13) + char(10);
                set @prepared_code = @prepared_code + '''''''+replace(' + @yet_another_variable + ',@qraw, @qrep)+''''''';
            end
            else begin
                set @prepared_code = @prepared_code + replace(substring(@raw_code, @index, 1), '''', '''''');
                set @index = @index + 1;
            end;
        end;

        if substring(@raw_code, @index, 1) = '}'
            set @index = @index + 1;

        if @node_type = 1
        begin
            insert into #pushup_output
            select @prepared_code as core_prepared_code;
        end
        else if @node_type = 2
        begin
            insert into #pushup_output
            select @prepared_code as core_prepared_code;
        end
        else if @node_type = 0
        begin
            set @processed_code = @processed_code + 'declare @main nvarchar(max)=''' + @prepared_code + ''';' + char(13) + char(10);
        end;
    
    end;
    
end

go
