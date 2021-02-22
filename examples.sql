
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
