/*
    BEGENS (BEyond GENeric Sql) macroprocessor for MS SQL Server T-SQL;
    
    Version:
        Begens macro processor 1.0
    Author:
        Egor Promyshlennikov
    Date:
        Since 21 February 2021
        Last update 23 February 2021
    Contacts:
        https://github.com/Epromee
        https://vk.com/epromee
    
    The code is provided "as is", no warranty, no responsibility and all that stuff.
    Brand new license's gonna be added later.
    
    To install to custom schema, grep/search /*SCHEMA*/
    
    Macro-commands:
    
    !!{NO_SUBST} -- makes output of current block not be substituted.
    !!{DIRECT_INLINE} -- substitutes your code in the block directly to the compiled code.
                -- use DIRECT_INLINE for initializing temp tables and importing variables.
                -- DO NOT!!! use Begens macro inside the inlineable block.
    !!{DEFER_MAIN} -- instead of executing the last formed dynamic batch, it yields it as select
                   -- the whole code is still BEING runned, all $${}'s are launched and substituted
    !!{DECL_VAR}!!{YOUR_VAR}@@{block}  -- this is used to make a @@block result to be substituted next time
                                      -- when you call it again (you  an use $${block} as well, but it's
                                      -- gonna be computed only once)
     !!{YOUR_VAR} -- The name be different, like !!{MY_VAR}, !!{OUR_VAR}, !!{MY_SHIT} etc., if you
                 -- defined it as in previous macro construction, it would substitute @@{block} result once again
     !!{NO_IE}  -- This means "No Insert Exec". It is used to disable insert exec from $${} statements
                 -- and switches it to manual inserts
     !!{INSERT_INLINE} -- And this is the manual insert, you write in like this: "$${!!{INSERT_INLINE} select @@{useless_stuff};}"
    
*/

/* Cool big brain procedure to make my SQL code even more badass */
create procedure /*SCHEMA*/begens

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
        -- strict code inlining in the beginning (Not direct_inline I mean)
        -- checkout unclosed parenthesis in non-parent nodes
        -- process dummy parenthesis { as no operation
        -- don't emplace #t table if no $${} parenthesis was envolved
        -- aggregate variable declarations (so we won't have to write those dumb "declare" statements every time)
        
        -- add compile-time inline blocks
        -- make Begens code be procedurable, so that we can use input variables in Begens code
        
        -- add decorators to #t table (by default it gets aggregated by a concat, but what if something else as well)
        -- decorators must be: prefix, postfix and delimiter
        
        -- track variable assigns and auto-reuse common variables without allocating new
        
        -- add an option to comment in output tsql the original begens code
    */
    
    /* User called the procedure */
    if @index is null
    begin

        /* Track how many vars we have used throughout the whole recursive script */
        create table #used_variables(vcnt bigint);
        insert into #used_variables values(0);

        /* For pushing-up recursive call returns */
        create table #pushup_output(str nvarchar(max));
        
        /* Declared macro variables */
        create table #macro_variables(mvar nvarchar(255) unique clustered, assignee nvarchar(max));

        /* Go ahead */

        declare @my_processed_code nvarchar(max) = '';
        declare @my_index int = 1;

        exec /*SCHEMA*/begens @raw_code output, 0, @my_index output, @my_processed_code output, 0;

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

        /* macro flags */
        declare @no_substitution bit = 0;
        declare @direct_inlining bit = 0;
        declare @defer_main bit = 0;
        declare @next_macro_declare_var bit = 0;
        declare @no_insert_exec bit = 0;
        
        /* macro vars */
        declare @next_block_save_variable_at nvarchar(255);
        
        if @node_type = 0
        begin
            set @processed_code = @processed_code + 'declare @qraw varchar(10) = '''''''';' + char(13) + char(10);
            set @processed_code = @processed_code + 'declare @qrep varchar(10) = '''''''''''';' + char(13) + char(10);
            set @processed_code = @processed_code + 'declare @dy nvarchar(max);' + char(13) + char(10);
            set @processed_code = @processed_code + 'create table #t(id bigint identity(1, 1) unique clustered, t nvarchar(max));' + char(13) + char(10);
        end;

        while @index <= len(@raw_code) and (substring(@raw_code, @index, 1) != '}' or @node_type = 0)
        begin

            declare @code_lookahead nvarchar(3) = substring(@raw_code, @index, 3);

            declare @yet_another_variable nvarchar(10);
            declare @previous_output nvarchar(max);
            
            declare @inserted_var nvarchar(max);

            if @code_lookahead = '!!{'
            begin
                -- TODO: forbid {} inside the macro calls
                declare @next_index_in_macro int = charindex('}', @raw_code, @index);
                declare @macro_call nvarchar(max) = substring(@raw_code, @index + 3, @next_index_in_macro - @index - 3);
                set @index = @next_index_in_macro + 1;
                
                if @next_macro_declare_var = 1
                begin
                    set @next_macro_declare_var = 0;
                    set @next_block_save_variable_at = @macro_call;
                end
                else if @macro_call = 'NO_SUBST'
                begin
                    set @no_substitution = 1;
                end
                else if @macro_call = 'DIRECT_INLINE'
                begin
                    set @direct_inlining = 1;
                    set @no_substitution = 1; -- implies NO_SUBST
                end
                else if @macro_call = 'DEFER_MAIN'
                begin
                    set @defer_main = 1;
                end
                else if @macro_call = 'DECL_VAR'
                begin
                    set @next_macro_declare_var = 1;
                end
                else if @macro_call = 'NO_IE'
                begin
                    set @no_insert_exec = 1;
                end
                else if @macro_call = 'INSERT_INLINE'
                begin
                    set @prepared_code = @prepared_code + ' insert into #t(t) ';
                end
                else if @macro_call in (select mvar from #macro_variables)
                begin
                    set @inserted_var = (select assignee from #macro_variables where mvar = @macro_call);
                    set @prepared_code = @prepared_code + @inserted_var;
                end;
            end
            else if @code_lookahead = '$${' or @code_lookahead = '@@{'
            begin
                set @index = @index + 3;
                
                declare @exact_subquery int = iif(@code_lookahead = '$$', 2, 1);
                exec /*SCHEMA*/begens @raw_code output, 0, @index output, @processed_code output, @exact_subquery;

                set @previous_output = (select str from #pushup_output);
                truncate table #pushup_output;
            
                -- direct inlining must be before no_subst handle, because it impiles no_subst, but actually requires the output
                if @direct_inlining = 1
                begin
                    set @direct_inlining = 0;

                    declare @direct_prepared_code nvarchar(max) = 'insert into #direct_inline_code select ''' + @previous_output + '''';
                    create table #direct_inline_code(t nvarchar(max));
                    exec(@direct_prepared_code);
                    set @direct_prepared_code = (select t from #direct_inline_code);
                    drop table #direct_inline_code;

                    set @processed_code = @processed_code + '/* DIRECT_INLINE begin */' + char(13) + char(10);
                    set @processed_code = @processed_code + @direct_prepared_code + char(13) + char(10);
                    set @processed_code = @processed_code + '/* DIRECT_INLINE end */' + char(13) + char(10);
                end;
                
                if @no_substitution = 1
                begin
                    set @no_substitution = 0;
                    set @previous_output = '';
                end;
                
                /* optimization for returning nothing */
                /* FROM $$*/
                if @previous_output != ''
                begin
                    set @yet_another_variable = '@v' + cast((select top 1 vcnt from #used_variables) as nvarchar(10));
                    update #used_variables set vcnt = vcnt + 1;
                
                    if @code_lookahead = '$${'
                    begin
                        set @processed_code = @processed_code + 'set @dy=N''' + @previous_output + ''';' + char(13) + char(10);
                        set @processed_code = @processed_code + 'declare ' + @yet_another_variable + ' nvarchar(max) = '''';' + char(13) + char(10);
                        if @no_insert_exec = 1
                        begin
                            set @processed_code = @processed_code + 'exec(@dy);' + char(13) + char(10);
                            set @no_insert_exec = 0;
                        end else
                            set @processed_code = @processed_code + 'insert into #t(t) exec(@dy);' + char(13) + char(10);
                        set @processed_code = @processed_code + 'select ' + @yet_another_variable + ' = ' + @yet_another_variable + ' + t from #t order by id;' + char(13) + char(10);
                        set @processed_code = @processed_code + 'truncate table #t;' + char(13) + char(10);
                        set @inserted_var = '''+' + @yet_another_variable + '+''';
                    
                    end
                    else if @code_lookahead = '@@{'
                    begin
                        set @processed_code = @processed_code + 'declare ' + @yet_another_variable + ' nvarchar(max)=N''' + @previous_output + ''';' + char(13) + char(10);
                        set @inserted_var = '''''''+replace(' + @yet_another_variable + ',@qraw, @qrep)+N''''''';
                    end
                    
                    set @prepared_code = @prepared_code + @inserted_var;
                    
                    if @next_block_save_variable_at is not null
                    begin
                        /* create a new macro var if doesn't exist */
                        insert into #macro_variables(mvar)
                        select (@next_block_save_variable_at)
                        except
                        select mvar from #macro_variables;
                        
                        /* set it a new in-code var */
                        update #macro_variables
                        set assignee = @inserted_var
                        where mvar = @next_block_save_variable_at;
                        
                        /* done, no need to declare again */
                        set @next_block_save_variable_at = null;
                    end;
                
                end
                else begin
                    if @code_lookahead = '@@{'
                        set @prepared_code = @prepared_code + '''''''''';
                end;
                
            end
            else begin
                set @prepared_code = @prepared_code + replace(substring(@raw_code, @index, 1), '''', '''''');
                set @index = @index + 1;
            end;
        end;

        if substring(@raw_code, @index, 1) = '}'
            set @index = @index + 1;

        if @node_type = 1 or @node_type = 2
        begin
            insert into #pushup_output
            select @prepared_code as core_prepared_code;
        end
        else if @node_type = 0
        begin
            set @processed_code = @processed_code + 'declare @main nvarchar(max)=N''' + @prepared_code + ''';' + char(13) + char(10);
            set @processed_code = @processed_code + 'drop table #t;' + char(13) + char(10);
            
            if (@defer_main = 0)
            begin
                set @processed_code = @processed_code + 'exec(@main);' + char(13) + char(10);
            end
            else
            begin
                set @processed_code = @processed_code + 'select @main as deferred_main;' + char(13) + char(10);
            end
        end;
    
    end;
    
end


go
