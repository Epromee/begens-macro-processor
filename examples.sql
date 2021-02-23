
/* Example 1: */

-- this guy is gonna be executed directly
exec begens '

    print @@{Something cool is gonna be executed};
    
    exec (@@{
        print @@{Imagine dynamic queries became more powerful?};
        
        exec(@@{
            
            print @@{I mean, this is a string, and @@{this is an inner string @@{ and this guy is even more inner} wow 0_0 } o m g};
            
            print @@{$${
                    print @@{Hello world, I'' the first message here};
                    select @@{And I''m the last};
                }}
        });
    });

';

-- this guy will drop you a normal TSQL code, which you can execute later
exec begens '

    print @@{Something cool is gonna be executed};
    
    exec (@@{
        print @@{Imagine dynamic queries became more powerful?};
        
        exec(@@{
            
            print @@{I mean, this is a string, and @@{this is an inner string @@{ and this guy is even more inner} wow 0_0 } o m g};
            
            print @@{$${
                    print @@{Hello world, I'' the first message here};
                    select @@{And I''m the last};
                }}
        });
    });

', 1; -- <-- see this?

go

/* Example 2: */

-- see how this guy !!{NO_SUBST} supresses the output?
exec begens '
    select @@{hello world} as hello_world;
    select @@{!!{NO_SUBST}I hate world} as missing_information;
    select @@{goodbye world} as goodbye_world;
', 0;

/* Example 3: */

-- this dude uses DIRECT_INLINE to make a temporary table and then use it
exec begens '
    @@{!!{DIRECT_INLINE}
        create table #test(str nvarchar(max));
        insert into #test values (''stuff1''), (''stuff2''), (''stuff3''); --see good old strings? NEVER use macro inside DIRECT_INLINE (yet) -_-
    }

    /* Here goes the normal Begens code */
    select @@{$${ select * from #test}} as sample_1;

', 0;

/* Example 4: */

-- This one disables insert-exec in $$ statement and replaces it with manual inserts
exec begens '
    select @@{!!{NO_IE}$${
        select @@{One } as outside
        !!{INSERT_INLINE} select @@{Two }
        select @@{Three } as outside
        !!{INSERT_INLINE} select @@{Four }
        select @@{Five } as outside
        !!{INSERT_INLINE} select @@{Six }
        select @@{Seven }
    }} as inside;
', 0;

-- This one show differences
exec begens '
    select @@{Monday: $${ select@@{sun} }} as one;
    select @@{Tuesday: !!{NO_IE}$${ select@@{rain} }} as two;
    select @@{Wednesday: !!{NO_IE}$${ !!{INSERT_INLINE} select@@{fog} }} as wednesday;
', 0;

/* Example 5: */

-- shows basic macro variable manipulation
exec begens '
    select !!{DECL_VAR}!!{BRUH}@@{hello world} as cnam
    select !!{BRUH} as cnam2
', 0;

/* Example 6: */

-- consider non-normalized table which we have obtained somehow
create table #test(
    city_id int,
    city_name varchar(255),
    person_id int,
    person_name varchar(255),
    occupation_id int,
    occupation_name varchar(255)
)

-- I said somehow
insert into #test values(16, 'Krasnodar', 54, 'Epromee', 1337, 'Developer');
insert into #test values(17, 'Moscow', 57, 'John Doe', 98, 'Clerk');

-- Well, now we want to select only those columns, which contain "name" in their, well, name
exec begens '
    
    /* substitute previously selected column names and exec the script */
    select $${
        
        /* select needed column names*/
        declare @tmp varchar(max) = (select @@{$${
            select name + @@{, }
            from tempdb.sys.columns c
            where c.object_id = object_id(@@{tempdb..#test}) and c.name like @@{%name%}
            order by column_id;
        }} t);

        /* remove the last comma */
        select left(@tmp, len(@tmp + @@{,}) - 3);
    }
    from #test;
';


/* Example 7: */

-- Just like the previous one, but consider 2 different tables with the same metadata:
create table #test1(
    city_id int,
    city_name varchar(255),
    person_id int,
    person_name varchar(255),
    occupation_id int,
    occupation_name varchar(255)
)

create table #test2(
    city_id int,
    city_name varchar(255),
    person_id int,
    person_name varchar(255),
    occupation_id int,
    occupation_name varchar(255)
)

-- And with different data:
insert into #test1 values(16, 'Krasnodar', 54, 'Epromee', 1337, 'Developer');
insert into #test2 values(17, 'Moscow', 57, 'John Doe', 98, 'Clerk');

exec begens '
    
    /* substitute previously selected column names and exec the script, and assign it to a variable */
    select !!{DECL_VAR}!!{THOSE_COLUMNS}$${
        
        /* select needed column names*/
        declare @tmp varchar(max) = (select @@{$${
            select name + @@{, }
            from tempdb.sys.columns c
            where c.object_id = object_id(@@{tempdb..#test1}) and c.name like @@{%name%}
            order by column_id;
        }} t);

        /* remove the last comma */
        select left(@tmp, len(@tmp + @@{,}) - 3);
    }
    from #test1;
    
    /* and let''s do it once again, but now with another table */
    select !!{THOSE_COLUMNS} from #test2;
', 0;
