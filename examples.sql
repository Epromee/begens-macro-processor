
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



