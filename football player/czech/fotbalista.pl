print "### Started and doing setup ###\n";

use strict;
use warnings;
use Term::ReadKey;
use utf8;
use autodie;
use Treex::Core::Common;
use Treex::Core::Scenario;
use POSIX;
#use String::Approx qw(amatch);
use Encode;

#sub say { print @_, "\n"; }

my $line = "";
my $logfile;

binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

{
    # I want my arguments to be UTF-8
    use I18N::Langinfo qw(langinfo CODESET);
    use Encode qw(decode);
    my $codeset = langinfo(CODESET);
    @ARGV = map { decode $codeset, $_ } @ARGV;
}

# konstanty
my $reply_count = 0;
my $cycle = 0;
my $cyc_lim = 25;

my $pst_pochvala = 5;

my $keyword = "";
my %keys;

sub speak {
    my ($line) = @_;

    say "Hráč: " . $line;
    say $logfile $line;
    
    u_said($line);
    print "> ";

    return;
}

sub run_dialogue
{
    initialize();
    respond(); 
    while($line = <>)
    {
        if ($line eq ":q\n") {
            exit 0;
        }
        if ($line eq ":s\n") {
            # zacit rozhovor odznova
        }
        #print "> ", $line;
        $reply_count += 1;
        #say "čekám na ENTER";
        #<STDIN>;
        respond();
    }
}

sub init_use {
    my $num = shift;
    my @array = ();
    for (my $i=0; $i < $num; $i++) {
        push(@array, 0);
    }
    return @array;
}

# základní odpovědi
my @greeting = (
    "Dobrý den!",
    "Zdravím vás."
    );
my @greeting_use = init_use(scalar @greeting);

my @nothing_to_say = (
	"Další otázku, prosím.", 
	"Bez komentáře."
	);
my @nothing_to_say_use = init_use(scalar @nothing_to_say);

my @next_question_prompt = (
	"Co by vás zajímalo?",
	"Ptejte se, prosím.",
    "Předpokládám, že máte nějakou otázku?"
    );
my @next_question_prompt_use = init_use(scalar @next_question_prompt);

my @end_dialogue = (
	"Promiňte, už mě volá trenér.", 
	"Omlouvám se, ale musím jít, za chvíli otevírá můj oblíbený bar.",
    "Omlouvám se, už musím jít, těším se na masáž."
    );
my @end_dialogue_use = init_use(scalar @end_dialogue);

my @too_short = (
	"Hrozně rád bych vám něco odpověděl, ale teď vážně není na co. Zkuste se trochu snažit.",
	"Zkuste mi dávat pořádné otázky, když už tu s vámi trávím čas.",
    "Vám asi neplatí podle počtu písmen, že? Tak alespoň tady zkuste něco trochu delšího."
    );
my @too_short_use = init_use(scalar @too_short);

my @repeat_yourself = (
    "Zkuste trochu obměnit, co mi říkáte.",
    "Malá změna taky změna, tak nějakou zkuste."
    );
my @repeat_yourself_use = init_use(scalar @repeat_yourself);

my @angry = (
    "Nezlobte se, ale já tu nejsem jen pro vaši zábavu.",
    "Podívejte, takhle by to nešlo.",
    );
my @angry_use = init_use(scalar @angry);

my @kolega = (
    "Mrzakovič", "Kovalský", "Pražák", "Klicpera", "Svoboda", "Hrubeš", "Kubát", "Černý", "Kaluža"
    );
my @kolega_use = init_use(scalar @kolega);

my @noun_blank = (	
    "Tak určitě.",
    "Jak říkám.",
    "No asi určitě.",
    "Souhlasím.",
    "Přesně jak říkáte.",
    "Fotbal nemá logiku.",
    "Tak jasně.",
    "No ovšem."
    );
my @noun_blank_use = init_use(scalar @noun_blank);

my @praise = (
    "To je dobrá otázka.",
    "To je velmi dobrá otázka.",
    "To je výborná otázka.",
    "To není špatná otázka."
    );
my @praise_use = init_use(scalar @praise);

my @no_question = (
    "To už vám došly otázky?",
    "Opravdu už se nechcete zeptat na nic dalšího?",
    "Ještě něco, co by vás zajímalo...?",
    "Podívejte se prosím do úkolníčku, na co dalšího se chcete zeptat.",
    "Jestli už tam nic nemáte, tak bych šel do sprchy."
    );
my @no_question_use = init_use(scalar @no_question);

sub usage_ok {
    my @array = @_;
    my $count = 0;
    foreach my $num (@array) {   
       if ( $num == 0) {
            $count++;
        }        
    }
    if ($count == 0) {
        return 0;
    } else {
        return 1;
    }
}

sub greeting {
    if (usage_ok(@greeting_use) == 0) {
        for my $i (0..scalar(@greeting_use)-1) {
            $greeting_use[$i] = 0;
        }
    }
    my $idx;
    do {
        $idx = rand(scalar(@greeting));
    } while ($greeting_use[$idx] == 1);
    $greeting_use[$idx] = 1;
    return $greeting[$idx];
}

sub nothing_to_say {
    if (usage_ok(@nothing_to_say_use) == 0) {
        for my $i (0..scalar(@nothing_to_say_use)-1) {
            $nothing_to_say_use[$i] = 0;
        }
    }
    my $idx;
    do {
        $idx = rand(scalar(@nothing_to_say_use));
    } while ($nothing_to_say_use[$idx] == 1);
    $nothing_to_say_use[$idx] = 1;
    return $nothing_to_say[$idx];
}

sub next_question_prompt {
    if (usage_ok(@next_question_prompt_use) == 0) {
        for my $i (0..scalar(@next_question_prompt_use)-1) {
            $next_question_prompt_use[$i] = 0;
        }
    }
    my $idx;
    do {
        $idx = rand(scalar(@next_question_prompt_use));
    } while ($next_question_prompt_use[$idx] == 1);
    $next_question_prompt_use[$idx] = 1;
    return $next_question_prompt[$idx];
}

sub end_dialogue {
    if (usage_ok(@end_dialogue_use) == 0) {
        for my $i (0..scalar(@end_dialogue_use)-1) {
            $end_dialogue_use[$i] = 0;
        }
    }
    my $idx;
    do {
        $idx = rand(scalar(@end_dialogue_use));
    } while ($end_dialogue_use[$idx] == 1);
    $end_dialogue_use[$idx] = 1;
    return $end_dialogue[$idx];
}

sub too_short {
    if (usage_ok(@too_short_use) == 0) {
        for my $i (0..scalar(@too_short_use)-1) {
            $too_short_use[$i] = 0;
        }
    }
    my $idx;
    do {
        $idx = rand(scalar(@too_short_use));
    } while ($too_short_use[$idx] == 1);
    $too_short_use[$idx] = 1;
    return $too_short[$idx];
}

sub repeat_yourself {
    if (usage_ok(@repeat_yourself_use) == 0) {
        for my $i (0..scalar(@repeat_yourself_use)-1) {
            $repeat_yourself_use[$i] = 0;
        }
    }
    my $idx;
    do {
        $idx = rand(scalar(@repeat_yourself_use));
    } while ($repeat_yourself_use[$idx] == 1);
    $repeat_yourself_use[$idx] = 1;
    return $repeat_yourself[$idx];
}

sub angry {
    if (usage_ok(@angry_use) == 0) {
        for my $i (0..scalar(@angry_use)-1) {
            $angry_use[$i] = 0;
        }
    }
    my $idx;
    do {
        $idx = rand(scalar(@angry_use));
    } while ($angry_use[$idx] == 1);
    $angry_use[$idx] = 1;
    return $angry[$idx];
}

sub noun_blank {
    if (usage_ok(@noun_blank_use) == 0) {
        for my $i (0..scalar(@noun_blank_use)-1) {
            $noun_blank_use[$i] = 0;
        }
    }
    my $idx;
    do {
        $idx = rand(scalar(@noun_blank_use));
    } while ($noun_blank_use[$idx] == 1);
    $noun_blank_use[$idx] = 1;
    return $noun_blank[$idx];
}

sub kolega {
    if (usage_ok(@kolega_use) == 0) {
        for my $i (0..scalar(@kolega_use)-1) {
            $kolega_use[$i] = 0;
        }
    }
    my $idx;
    do {
        $idx = rand(scalar(@kolega_use));
    } while ($kolega_use[$idx] == 1);
    $kolega_use[$idx] = 1;
    return $kolega[$idx];
}

sub praise {
    if (usage_ok(@praise_use) == 0) {
        for my $i (0..scalar(@praise_use)-1) {
            $praise_use[$i] = 0;
        }
    }
    my $idx;
    do {
        $idx = rand(scalar(@praise_use));
    } while ($praise_use[$idx] == 1);
    $praise_use[$idx] = 1;
    return $praise[$idx];
}

sub no_question {
    if (usage_ok(@no_question_use) == 0) {
        for my $i (0..scalar(@no_question_use)-1) {
            $no_question_use[$i] = 0;
        }
    }
    my $idx;
    do {
        $idx = rand(scalar(@no_question_use));
    } while ($no_question_use[$idx] == 1);
    $no_question_use[$idx] = 1;
    return $no_question[$idx];
}

my @soutez;

open(my $f_soutez, '<:encoding(UTF-8)', "soutez")
 or die "Couldn't open database soutez";

while (my $row = <$f_soutez>) {
    chomp $row;
    push(@soutez, $row);
}

my @akce;

open(my $f_akce, '<:encoding(UTF-8)', "akce")
 or die "Couldn't open database akce";

while (my $row = <$f_akce>) {
    chomp $row;
    push(@akce, $row);
}

my @vysledek;

open(my $f_vysledek, '<:encoding(UTF-8)', "vysledek")
 or die "Couldn't open database vysledek";

while (my $row = <$f_vysledek>) {
    chomp $row;
    push(@vysledek, $row);
}

my @fans;

open(my $f_fans, '<:encoding(UTF-8)', "fans")
 or die "Couldn't open database fans";

while (my $row = <$f_fans>) {
    chomp $row;
    push(@fans, $row);
}


my @hrac;

open(my $f_hrac, '<:encoding(UTF-8)', "hrac")
 or die "Couldn't open database hrac";

while (my $row = <$f_hrac>) {
    chomp $row;
    push(@hrac, $row);
}

# init

my $scenario_string = '
    Util::SetGlobal language=cs
    W2A::CS::Tokenize
    W2A::CS::TagMorphoDiTa lemmatize=1
';

my $scenario = Treex::Core::Scenario->new(from_string => $scenario_string);
$scenario->start();

use Treex::Tool::Depfix::CS::FormGenerator;
my $generator = Treex::Tool::Depfix::CS::FormGenerator->new();

sub create_document_from_sentence {
    my ($sentence) = @_;

    use Treex::Core::Document;
    my $document = Treex::Core::Document->new();
    my $bundle = $document->create_bundle();
    my $zone = $bundle->create_zone('cs');
    $zone->set_sentence($sentence);

    return $document;
}

use Treex::Tool::Depfix::CS::TagHandler;
sub set_tag_cat {
    my ($tag, $cat, $value) = @_;

    return Treex::Tool::Depfix::CS::TagHandler::set_tag_cat($tag, $cat, $value);
}
sub get_tag_cat {
    my ($tag, $cat) = @_;

    return Treex::Tool::Depfix::CS::TagHandler::get_tag_cat($tag, $cat);
}

# analysis methods

my @nouns;
my @adjectives;
my @verbs;
my @words;
my $first_word;

sub find_nouns {
    my @anodes = @_;
    @nouns = ();
    foreach my $anode (@anodes) {	
	   if ( $anode->tag =~ /^N/) {
	        push(@nouns, $anode->lemma);
    	}
    }
}

sub find_adjectives {
    my @anodes = @_;
    @adjectives = ();
    foreach my $anode (@anodes) {
	   if ( $anode->tag =~ /^A/) {
	        push(@adjectives, $anode->lemma);
	   }
    }
}

sub find_verbs {
    my @anodes = @_;
    @verbs = ();
    foreach my $anode (@anodes) {
	   if ( $anode->tag =~ /^V/) {
	        push(@verbs, $anode->lemma);
    	}
    }
}

sub find_last_noun {
    my ($anodes) = @_;
    my $node;
    foreach my $anode (@$anodes) {
        # speak ($anode->form . " " . $anode->lemma . " " . $anode->tag );
        if ( $anode->tag =~ /^N/) {
            $node = $anode;
        }
    }
    return $node;
}

sub find_last_adjective {
    my ($anodes) = @_;
    my $node;
    foreach my $anode (@$anodes) {
        # speak ($anode->form . " " . $anode->lemma . " " . $anode->tag );
        if ( $anode->tag =~ /^A/) {
            $node = $anode;
        }
    }
    return $node;
}

sub find_last_full_verb {
    my ($anodes) = @_;
    my $node;
    foreach my $anode (@$anodes) {
        # speak ($anode->form . " " . $anode->lemma . " " . $anode->tag );
        if ( $anode->tag =~ /^V/ && $anode->lemma !~ /být|mít|žít/) {
            $node = $anode;
        }
    }
    return $node;
}

sub find_words {
    my @anodes = @_;
    @words = ();
    $first_word = @anodes[0]->lemma;
    foreach my $anode (@anodes) {
        push(@words, $anode->lemma);
    }
}

my %told_ya = ();
my %told_me = ();

#sub used_key {
#
#}

sub i_said {
    my $sentence = join(' ', @_);
    $told_ya{$sentence} = 1;
}

sub u_said {
    my $sentence = join(' ', @_);
    $told_me{$sentence} = 1;
}

sub q_check {
    my @anodes = @_;
    foreach my $anode (@anodes) {
        if ($anode->lemma eq "?") {
            return 1;
        }
        my $subpos = get_tag_cat($anode->tag, 'subpos');
        if ($subpos eq "i") { #sloveso je v imperativu
            return 1;
        }
    }
    return 0;
}

# dialogue methods

my $last_was_q;

### momentalne se nepouziva, nema to totiz moc velke vyuziti
# sub pro nazor
my @opinion_verbs = ("myslet", "myslit", "myslit_:T", "říkat_:T");
my @opinion_nouns = ("názor", "dojem");

sub nazor {
    my ($anodes) = @_;
    my $what = undef;    
    my $speak = undef;
    my $node = undef;

    foreach my $verb (@opinion_verbs) {
	   if ($verb ~~ @verbs) {
	       $node = $verb;
	       $what = "v";
            last;
	   }
    }
    foreach my $noun (@opinion_nouns) {
	   if ($noun ~~ @nouns) {
	       $node = $noun;
	       $what = "n";
            last;
	   }
    }

    my $cyc_const = 0;
    if (defined $what){
        do {
            if ($what eq "n") {
                given (int(rand(2))) {
                    when(0) {$speak = "Můj " . $node . " není důležitej, pravdu má rozhodčí.";}
                    when(1) {$speak = "Můj " . $node . " není důležitej, pravdu má trenér.";}
					when(2) {$speak = "Můj " . $node . " není důležitej, pravdu má manželka.";}
                    when(3) {$speak = "Nemyslím si, že na něčem takovém by záleželo.";}
                }
            }
            if ($what eq "v") {
                given (int(rand(2))) {
                    when(0) { $speak = "Já nevím, řekl bych, no, to je těžký říct nějak jasně.";}
                    when(1) { $speak = "Myslím, že vše je v souladu se stranickou linií.";}
                }
            }
            $cyc_const++;
        } while (exists $told_ya{$speak} && $cyc_const < $cyc_lim)
    }
    if ($cyc_const >= $cyc_lim) {return undef;}
    else {return $speak;}
}

my @soutez_use = init_use(18);
sub soutez {
    my ($anodes) = @_;
    my $speak;
    my $node;
    my $done = 0;

    foreach my $soutez (@soutez) {
         if ($soutez ~~ @nouns) {
            
            foreach my $anode (@$anodes) {
                if ($anode->lemma eq $soutez) {
                    $node = $anode;
                    $done = 1;
                    last;
                }
            }
            if ($done == 1) {last;}
        }
    }

    my $cyc_const = 0;
        
    if (defined $node) {    
        my $number = get_tag_cat($node->tag, 'number');
        my $gender = get_tag_cat($node->tag, 'gender');
        my $used = -1;
        do {    
            $used = int(rand(18));
            given ($used) {
            	when(0) {
            		$speak = "Máme to ve svých rukou.";
            	}
            	when(1) {
            		$speak = "Hlavní je, že si teď hraní užíváme.";
            	}
            	when(2) {
            		$speak = "Podle mě je důležitý jít zápas od zápasu.";
            	}
            	when(3) {
            		$speak = "Musíme se soustředit jenom sami na sebe a uvidíme, kam nás to vynese.";
            	}
            	when(4) {
            		$speak = "Pro nás to znamená, že to musíme stáhnout, v což věřím.";
            	}
            	when(5) {
            		$speak = "Dneska se mi to hrozně těžko hodnotí.";
            	}
                when(6) {
                    my $tag1 = set_tag_cat($node->tag, 'case', '4');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag1);
                    $speak = $form . " už si nenecháme utéct.";
                }
                when(7) {
                	$speak = "Bylo to důležitý, od začátku sezony sme se trápili, konečně sme to protrhli.";
                }
                when(8) {
                	$speak = "Teď musíme vyhrát zbylý zápasy a čekat na zaváhání soupeřů.";
                }
                when(9) {
                	$speak = "Na ostatní se nekoukáme, jdeme od zápasu k zápasu.";
                }
                when(10) {
                	my $tag1 = set_tag_cat($node->tag, 'case', '4');
                    my $form = lcfirst $generator->get_form($node->lemma, $tag1);
                    $speak = "Na " . $form . " vůbec nemyslím.";
                }
				when(11) {
                	my $tag1 = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag1);
                    $speak = $form . " nám vyhovuje.";
                }
                when(12) {
                	$speak = "Dneska už nejsou žádní slabí soupeři.";
                }
                when(13) {
                	$speak = "Kvalita týmů je hrozně vyrovnaná.";
                }
                when(14) {
                	$speak = "Každý dneska může porazit každého.";
                }
                when(15) {
                	$speak = "Já musím říct, že jsem spokojenej, určitě to moje očekávání splnilo.";
                }
                when(16) {
                	$speak = "Šance furt je.";
                }
                when(17) {
                	my $tag1 = set_tag_cat($node->tag, 'case', '4');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag1);
                    $speak = $form . " teď neřešíme.";
                }
            }
            $cyc_const++;
        } while ( @soutez_use[$used]==1 && $cyc_const < $cyc_lim);
        $keyword = $node->lemma;
        if (!defined $keys{$keyword} ) {
            @soutez_use[$used] = 1;
        }
    }
    $keyword = "";
    if ($cyc_const >= $cyc_lim) { 
        return undef; 
    } else {
        if (defined $node) {$keyword = $node->lemma;}
        return $speak;
    }
}

my @akce_use = init_use(9);
sub akce {
    my ($anodes) = @_;
    my $speak;
    my $node;
    my $done = 0;

    foreach my $akce (@akce) {
         if ($akce ~~ @nouns) {
            
            foreach my $anode (@$anodes) {
                if ($anode->lemma eq $akce) {
                    $node = $anode;
                    $done = 1;
                    last;
                }
            }
            if ($done == 1) {last;}
        }
    }

    my $cyc_const = 0;
        
    if (defined $node) {    
        my $number = get_tag_cat($node->tag, 'number');
        my $gender = get_tag_cat($node->tag, 'gender');
        my $used = -1;
        do {    
            $used = int(rand(9));
            given ($used) {
            	when(0) {
            		$speak = "Bylo to špatně posouzený.";
            	}
            	when(1) {
            		$speak = "Záleží na tom, jak to rozhodčí posoudí.";
            	}
            	when(2) {
            		$speak = "Tu situaci jsem pořádně neviděl.";
            	}
            	when(3) {
            		$speak = "Celý stadion to viděl.";
            	}
            	when(4) {
                    my $tag1 = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag1);
                    $speak = $form . ", tak to bylo směšný.";
                }
                when(5) {
                	my $tag1 = set_tag_cat($node->tag, 'case', '4');
                	$tag1 = set_tag_cat($node->tag, 'number', 'S');
                    my $form = lcfirst $generator->get_form($node->lemma, $tag1);
                    my $num = int(rand(90));
                    $speak = "V " . $num . ". minutě měl mít soupeř " . $form . ", takže potom se ten zápas nějak odvíjel.";
                }
				when(6) {
                	my $tag1 = set_tag_cat($node->tag, 'case', '4');
                    my $form = lcfirst $generator->get_form($node->lemma, $tag1);
                    $speak = "O " . $form . " se určitě nejednalo.";
                }
                when(7) {
                	$speak = "Tyhle situace nejsou nikdy lehký.";
                }
                when(8) {
                	my $tag1 = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag1);
                    $speak = $form . " nic moc.";
                }
            }
            $cyc_const++;
        } while ( @akce_use[$used]==1 && $cyc_const < $cyc_lim);
        $keyword = $node->lemma;
        if (!defined $keys{$keyword} ) {
            @akce_use[$used] = 1;
        }
    }
    $keyword = "";
    if ($cyc_const >= $cyc_lim) { 
        return undef; 
    } else {
        if (defined $node) {$keyword = $node->lemma;}
        return $speak;
    }
}

my @vysledek_use = init_use(16);
sub vysledek {
    my ($anodes) = @_;
    my $speak;
    my $node;
    my $done = 0;

    foreach my $vysledek (@vysledek) {
         if ($vysledek ~~ @nouns) {
            
            foreach my $anode (@$anodes) {
                if ($anode->lemma eq $vysledek) {
                    $node = $anode;
                    $done = 1;
                    last;
                }
            }
            if ($done == 1) {last;}
        }
    }

    my $cyc_const = 0;
        
    if (defined $node) {    
        my $number = get_tag_cat($node->tag, 'number');
        my $gender = get_tag_cat($node->tag, 'gender');
        my $used = -1;
        my $not_fitting = 0;
        do {    
        	$not_fitting = 0;
            $used = int(rand(16));
            given ($used) {
            	when(0) {
            		$speak = "Celý zápas byli zalezlí a čekali na brejk.";
            	}
            	when(1) {
            		$speak = "Chtěli jsme hrát fotbal.";
            	}
            	when(2) {
            		$speak = "Když nedáte gól, nemůžete vyhrát.";
            	}
            	when(3) {
            		$speak = "Tak bylo to hrozně těžké utkání, protože vesměs celý zápas jsme se bránili, dvě tři šance jsme tam měli, ale chvilkama jsme měli štěstí, ale říkám, hrozně těžký zápas.";
            	}
            	when(4) {
            		$speak = "Spokojenost.";
            		if ($node->lemma == "porážka" || $node->lemma == "prohra") {$not_fitting = 1;}
            	}
            	when(5) {
            		$speak = "Dneska nás vycvičili v efektivitě.";
            	}
            	when(6) {
            		$speak = "Můžem mít radost z předvedenýho výkonu, protože ten výkon byl bez chyb, jezdili jsme.";
            	}
            	when(7) {
            		$speak = "V první půli oni nevěděli, co na nás hrát, my sme nějaký náznaky měli, v druhym poločase nás položil ten gól, pak už to bylo těžký.";
            		if ($node->lemma == "výhra" || $node->lemma == "vítězství") {$not_fitting = 1;}
            	}
            	when(8) {
            		$speak = "Doufám, že prostě to půjde už jenom nahoru a že takových zápasů bude už co nejmíň jenom.";
            		if ($node->lemma == "výhra" || $node->lemma == "vítězství") {$not_fitting = 1;}
            	}
            	when(9) {
            		my $tag1 = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag1);
                    $speak = $form . ", jako je dnešní, no, co k tomu dodat.";
				}
				when(10) {
            		my $tag1 = set_tag_cat($node->tag, 'case', '4');
            		$tag1 = set_tag_cat($node->tag, 'number', 'S');
                    my $form = lcfirst $generator->get_form($node->lemma, $tag1);
                    $speak = "Na " . $form . " jako dneska si budu pamatovat ještě hodně dlouho.";
                }
                when(11) {
                	my $tag1 = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag1);
                    $speak = $form . " takovýho stylu nepřipadá v úvahu.";
                }
                when(12) {
                	$speak = "Musíme se zkoncentrovat na další zápas.";
                }
                when(13) {
                	$speak = "Dneska sme hráli dobře.";
                	if ($node->lemma == "porážka" || $node->lemma == "prohra") {$not_fitting = 1;}
                }
                when(14) {
                	$speak = "O poločase sme si řekli v kabině, že musíme makat pořád stejně.";
                	if ($node->lemma == "porážka" || $node->lemma == "prohra") {$not_fitting = 1;}
                }
                when(15) {
                	$speak = "Tenhle tejden sme měli jen po jednom tréninku a myslim, že nám to prospělo.";
                	if ($node->lemma == "porážka" || $node->lemma == "prohra") {$not_fitting = 1;}
                }

            }
            $cyc_const++;
        } while ( @vysledek_use[$used]==1 && $not_fitting==1 && $cyc_const < $cyc_lim);
        $keyword = $node->lemma;
        if (!defined $keys{$keyword} ) {
            @vysledek_use[$used] = 1;
        }
    }
    $keyword = "";
    if ($cyc_const >= $cyc_lim) { 
        return undef; 
    } else {
        if (defined $node) {$keyword = $node->lemma;}
        return $speak;
    }
}

my @fans_use = init_use(9);
sub fans {
    my ($anodes) = @_;
    my $speak;
    my $node;
    my $done = 0;

    foreach my $fans (@fans) {
         if ($fans ~~ @nouns) {
            
            foreach my $anode (@$anodes) {
                if ($anode->lemma eq $fans) {
                    $node = $anode;
                    $done = 1;
                    last;
                }
            }
            if ($done == 1) {last;}
        }
    }

    my $cyc_const = 0;
        
    if (defined $node) {    
        my $number = get_tag_cat($node->tag, 'number');
        my $gender = get_tag_cat($node->tag, 'gender');
        my $used = -1;
        do {    
            $used = int(rand(9));
            given ($used) {
            	when(0) {
            		$speak = "Prostě bomba.";
            	}
            	when(1) {
            		$speak = "Proto hrajeme fotbal.";
            	}
            	when(2) {
            		$speak = "Je to krásný, každýmu bych to přál zažít.";
            	}
            	when(3) {
            		$speak = "Tak já bych řekl, že sme si museli získat fanoušky na svojí stranu, což se nám, si myslim, dneska povedlo.";
            	}
            	when(4) {
            		$speak = "Dnes fanoušky musím pochválit, protože až do 90. minuty fandili opravdu skvěle.";
            	}
            	when(5) {
            		$speak = "Na mě fanoušci pískali, já sem si to zasloužil, nešlo mi to, všechno mi to odskakovalo, to se stává no, fanoušci maj právo vyjádřit svůj názor.";
            	}
            	when(6) {
            		$speak = "Já už sem na to zvyklej, tady nás moc nepodpořej.";
            	}
            	when(7) {
            		$speak = "Tak diváci byli fantastičtí dneska, patří jim obrovskej dík.";
            	}
            	when(8) {
            		$speak = "Diváci dnes byli dvanáctým hráčem, paráda.";
            	}
            }
            $cyc_const++;
        } while ( @fans_use[$used]==1 && $cyc_const < $cyc_lim);
        $keyword = $node->lemma;
        if (!defined $keys{$keyword} ) {
            @fans_use[$used] = 1;
        }
    }
    $keyword = "";
    if ($cyc_const >= $cyc_lim) { 
        return undef; 
    } else {
        if (defined $node) {$keyword = $node->lemma;}
        return $speak;
    }
}

my @hrac_use = init_use(7);
sub hrac {
    my ($anodes) = @_;
    my $speak;
    my $node;
    my $done = 0;

    foreach my $hrac (@hrac) {
         if ($hrac ~~ @nouns) {
            
            foreach my $anode (@$anodes) {
                if ($anode->lemma eq $hrac) {
                    $node = $anode;
                    $done = 1;
                    last;
                }
            }
            if ($done == 1) {last;}
        }
    }

    my $cyc_const = 0;
        
    if (defined $node) {    
        my $number = get_tag_cat($node->tag, 'number');
        my $gender = get_tag_cat($node->tag, 'gender');
        my $used = -1;
        do {    
            $used = int(rand(7));
            given ($used) {
            	when(0) {
            		my $tag1 = set_tag_cat($node->tag, 'case', '4');
            		$tag1 = set_tag_cat($node->tag, 'number', 'P');
                    my $form = lcfirst $generator->get_form($node->lemma, $tag1);
            		$speak = "Soupeř má taky šikovný " . $form;
            	}
            	when(1) {
            		my $tag1 = set_tag_cat($node->tag, 'case', '1');
            		$tag1 = set_tag_cat($node->tag, 'number', 'P');
                    my $form = lcfirst $generator->get_form($node->lemma, $tag1);
            		$speak = "Soupeřovi " . $form . " jsou dobře připravený.";
            	}
            	when(2) {
            		my $tag1 = set_tag_cat($node->tag, 'case', '4');
                    my $form = lcfirst $generator->get_form($node->lemma, $tag1);
            		$speak = "Nikdy jsem neviděl " . $form . ", jako je on.";
            	}
            	when(3) {
            		my $tag1 = set_tag_cat($node->tag, 'case', '1');
                    my $form = lcfirst $generator->get_form($node->lemma, $tag1);
            		$speak = "Myslím, že jsem lepší než " . $form . " soupeře.";
            	}
            	when(4) {
            		my $tag1 = set_tag_cat($node->tag, 'case', '7');
            		$tag1 = set_tag_cat($node->tag, 'number', 'S');
                    my $form = lcfirst $generator->get_form($node->lemma, $tag1);
            		$speak = "S " . $form . " jako on je radost hrát.";
            	}
            	when(5) {
            		my $tag1 = set_tag_cat($node->tag, 'case', '4');
                    my $form = lcfirst $generator->get_form($node->lemma, $tag1);
            		$speak = "Myslím, že pro " . $form . " byl zápas těžký.";
            	}
            	when(6) {
					my $tag1 = set_tag_cat($node->tag, 'case', '1');
            		$tag1 = set_tag_cat($node->tag, 'number', 'S');
                    my $form = lcfirst $generator->get_form($node->lemma, $tag1);
            		$speak = "Moderní " . $form . " by hodně situací řešil jinak.";
            	}
            }
            $cyc_const++;
        } while ( @hrac_use[$used]==1 && $cyc_const < $cyc_lim);
        $keyword = $node->lemma;
        if (!defined $keys{$keyword} ) {
            @hrac_use[$used] = 1;
        }
    }
    $keyword = "";
    if ($cyc_const >= $cyc_lim) { 
        return undef; 
    } else {
        if (defined $node) {$keyword = $node->lemma;}
        return $speak;
    }
}

my @vykon_words = ('výkon','nasazení','úsilí');
my @vykon_use = init_use(18);
sub vykon {
    my ($anodes) = @_;
    my $speak;
    my $node;
    my $done = 0;

    my $cyc_const = 0;
    
    foreach my $word (@vykon_words) {
	   if ($word ~~ @words) {
	       $node = $word;
            last;
	   }
    }

    if (defined $node) {    
        my $number = get_tag_cat($node->tag, 'number');
        my $gender = get_tag_cat($node->tag, 'gender');
        my $used = -1;
        do {    
            $used = int(rand(18));
            given ($used) {
            	when(0) {
            		$speak = "";
            	}
            }
            $cyc_const++;
        } while ( @vykon_use[$used]==1 && $cyc_const < $cyc_lim);
        $keyword = $node->lemma;
        if (!defined $keys{$keyword} ) {
            @vykon_use[$used] = 1;
        }
    }
    $keyword = "";
    if ($cyc_const >= $cyc_lim) { 
        return undef; 
    } else {
        if (defined $node) {$keyword = $node->lemma;}
        return $speak;
    }
}

sub general_noun {
    my ($anodes) = @_;
    my $speak;
    my $noun = find_last_noun($anodes);
    
    if (length($noun) > 0) {
        $speak = noun_blank();
    }

    return $speak;
}

my @name_use = init_use(7);
sub name {
    my ($anodes) = @_;
    my $speak;
    my $name;
    foreach my $anode (@$anodes) {
        my $lema = $anode->lemma;
        if (substr($lema, -3) eq "_;S") {
            $name = $anode;
            last;
        }
    }
    my $cyc_const = 0;
    #if (defined $name && (name->lemma ne "Humphrey_;S")) {
    if (defined $name) {
        my $used = -1;
        do {
            $used = int(rand(7));
            given ($used) {
                when (0) {
                    my $tag = set_tag_cat($name->tag, 'case', '2');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
                    $speak = $form . " si hrozně vážíme, vždycky se obětuje pro tým.";
                }
                when (1) {
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
                    $speak = $form . " je hrozně super.";
                }
                when (2) {                                                                                                                                                                                                                                                                                              
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
                    $speak = $form . " potřebuje odbornou pomoc.";
                }
                when (3) {
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
                    $speak = $form . " je můj velký vzor.";
                }
                when (4) {
                    $speak = "Mhm, dal bych si říct ...";
                }
                when (5) {
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
                    $speak = $form . " je pro mě velkou inspirací.";
                }
            }
        $cyc_const++;
        } while (@name_use[$used]==1 && $cyc_const < $cyc_lim);
        $keyword = $name->lemma;
        if (!defined $keys{$keyword}) {
            @name_use[$used] = 1;
        }
        if ($cyc_const >= $cyc_lim) { return undef; }
        else {$keyword = $name->lemma;}
    }
    return $speak;
}

my @place_use = init_use(4);
sub place {
    my ($anodes) = @_;
    my $speak;
    my $place;

    foreach my $anode (@$anodes) {
        my $lema = $anode->lemma;
        if (substr($lema, -3) eq "_;G") {
            $place = $anode;
            last;
        }
    }
    my $cyc_const = 0;
    if (defined $place) {
        my $used = -1;
        do {
            $used = int(rand(4));
            given ($used) {
                when (0) {
                    $speak = "Tam jsem nikdy nebyl.";
                }
                when (1) {
                    my $tag = set_tag_cat($place->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
                    $speak = $form . " je hrozně fajn.";
                }
                when (2) {
                    my $tag = set_tag_cat($place->tag, 'case', '6');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
                    $speak = "V " . $form . " se hraje dobře.";
                }
                when (3) {
                    my $tag = set_tag_cat($place->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
                    $speak = $form . " má dost svých problémů.";
                }
                when (4) {
                	my $tag = set_tag_cat($place->tag, 'case', '6');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
                    $speak = "V " . $form . " je to pro mě dycky srdcovka.";
                }
            }
        $cyc_const++;
        } while ( @place_use[$used]==1 && $cyc_const < $cyc_lim);
        $keyword = $place->lemma;
        if (!defined $keys{$keyword}) {
            @place_use[$used] = 1;
        }
        if ($cyc_const >= $cyc_lim) { return undef; }
        else {$keyword = $place->lemma;}
    }
    return $speak;
}

my @kolik_use = init_use(3);
sub kolik {
	my ($anodes) = @_;
	my $speak;
	my $used = -1;
	if ("kolik" ~~ @words) {
		my $cyc_const = 0;
        do {
            $used = int(rand(3));
            given ($used) {
                when (0) {
                    $speak = "Hodně.";
                }
                when (1) {
                    $speak = "Málo.";
                }
                when (2) {
                    $speak = "Akorát.";
                }
            }
        $cyc_const++;
        } while ( @kolik_use[$used]==1 && $cyc_const < $cyc_lim);
        @kolik_use[$used] = 1;
        if ($cyc_const >= $cyc_lim) { return undef; }
    }

	return $speak;
}

my @byt_use = init_use(12);
sub byt {
	my ($anodes) = @_;
	my $speak;
	my $used = -1;
	if ("být" eq $first_word) {
		my $cyc_const = 0;
        do {
            $used = int(rand(12));
            given ($used) {
                when (0) { $speak = "Představte si, že ano."; }
                when (1) { $speak = "Já myslím, že jo."; }
                when (2) { $speak = "Tak jasně."; }
                when (3) { $speak = "To fakt ne."; }
                when (4) { $speak = "Neblbněte."; }
                when (5) { $speak = "Tak určitě."; }
                when (6) { $speak = "Přirozeně."; }
                when (7) { $speak = "To ani náhodou."; }
                when (8) { $speak = "Neřekl bych."; }
                when (9) { $speak = "Ano."; }
                when (10) { $speak = "Ne."; }
                when (11) { $speak = "Nezdá se mi."; }
            }
        $cyc_const++;
        } while ( @byt_use[$used]==1 && $cyc_const < $cyc_lim);
        @byt_use[$used] = 1;
        if ($cyc_const >= $cyc_lim) { return undef; }
    }

	return $speak;
}

sub uvod {
    my ($anodes) = @_;
    my $speak;

    if ("jak-3" ~~ @words && "se_^(zvr._zájmeno/částice)" ~~ @words) {

        if ("mít" ~~ @words) {
            $speak = "Suprově, to je jasný.";
            return $speak;
        } 
        if ("dařit_:T" ~~ @words) {
            $speak = "Tak mohlo by bejt i líp, ale znáte to.";
            return $speak;
        }
        if ("jmenovat_:T_:W" ~~ @words) {
            $speak = "Jak jako jak se jmenuju? Ty velký písmenka na dresu vám nestačí?";
            return $speak;
        }
    }
    if ("kolik" ~~ @words && "rok" ~~ @words && "ty" ~~ @words) {
        $speak = "Do fotbalového důchodu se ještě nechystám.";
        return $speak;
    }
    if ("jaký" ~~ @words && "věk" ~~ @words && "tvůj_^(přivlast.)" ~~ @words) {
        $speak = "Do fotbalového důchodu se ještě nechystám.";
        return $speak;
    }
    if ("jaký" ~~ @words && "hrát" ~~ @words) {
    	if ("klub" ~~ @words) {return "Za klub mého srdce, přeci.";}
    	if ("tým" ~~ @words) {return "Za tým mého srdce, přeci.";}
    }
    if ("život" ~~ @words && "vesmír" ~~ @words) {
        $speak = "42.";
        return $speak;
    }
    
    return $speak;
}


# ridici mechanismus
my $logname = strftime("./logs/%Y-%m-%d_%H-%M-%S.log", localtime(time));
open $logfile, '>:utf8', $logname;
	
#print $client "Session initialized.\n";
&run_dialogue();

sub reply_hierarchy {
    my @ar = @_;
    my $speak = "";
    
    $speak = uvod(@ar);
    $keyword = "";
    if (!defined $speak || length($speak) <= 0) {
    	$speak = kolik(@ar);
	    if (!defined $speak || length($speak) <= 0) {
	        $speak = name(@ar);
	        if (!defined $speak || length($speak) <= 0) {
	            $speak = place(@ar);
	            if (!defined $speak || length($speak) <= 0) {
	                $speak = vysledek(@ar);
	                if (!defined $speak || length($speak) <= 0) {
	                    $speak = soutez(@ar);
	                    if (!defined $speak || length($speak) <= 0) {
	                    	$speak = akce(@ar);
	                    	if (!defined $speak || length($speak) <= 0) {
		                    	$speak = fans(@ar);
		                    	if (!defined $speak || length($speak) <= 0) {
			                    	$speak = hrac(@ar);
			                        if (!defined $speak || length($speak) <= 0) {
			                            $speak = byt(@ar);
			                            if (!defined $speak || length($speak) <= 0) {
				                            $speak = general_noun(@ar);
				                            $keyword = "";
				                            if (!defined $speak || length($speak) <= 0) {
				                                #$speak = jaky(@ar);
				                                #if (!defined $speak || length($speak) <= 0) {
				                                    $speak = nothing_to_say();
				                                    $keyword = "";
				                                #}
				                            }
				                        }
			                        }
	                            }
	                        }
	                    }
	                }
	            }
	        }
        } # tady je to ve chvili, kdy neprosel uvod

        my $prob = int(rand(100));
        if ($prob <= $pst_pochvala) {
            $speak = praise() . " " . $speak;
        }
    }
    #say "keyword ". $keyword;
    #say $keys{$keyword};
    #say defined $keys{$keyword};
    #say $keyword;
    #say $keys{$keyword};
    #if (!defined $keys{$keyword} && length($keyword)>1) {
    #    say "ukladam " . $keyword;
    #}

    return $speak;
}

sub respond {
	#while (my $line = <>) {
        if ($reply_count == 0) {
            speak (greeting() . " " . next_question_prompt());
            return;
        }

	    print $logfile $line;

	    # analyze line
	    chomp $line;
    # opakuje identickou otazku
        if ( exists $told_me{$line} ) {
            speak (angry() . " " . repeat_yourself());
            return;
        }
        u_said($line);
        
	    my $document = create_document_from_sentence($line);
	    $scenario->apply_to_documents($document);
	    my @anodes = ($document->get_bundles())[0]->get_tree('cs','a')->get_descendants({ordered => 1});
		warn ( (join ' ', map { $_->form.'|'.$_->lemma.'|'.$_->tag  } @anodes) . "\n");
        find_nouns(@anodes);
	    find_verbs(@anodes);
	    find_adjectives(@anodes);
        find_words(@anodes);

        $last_was_q = q_check(@anodes);

	# kdyz je veta moc kratka, rekneme si o delsi
	    if ( @anodes == 0 ) {
            speak too_short();
            return;
	    }
	# kdyz dostanu ukoncujici sekvenci, skoncim
	    #if ( grep { $_->lemma eq 'konec' } @anodes ) {
        #    speak end_dialogue();
        #    last;
	    #}

        if (! $last_was_q) {
            speak no_question();
            return;
        }
    # hlavni odpovidaci mechanismus
        my $speak = reply_hierarchy(\@anodes);
	# je-li korektne zvoleno, co rici, rekni to, jinak popros o dalsi otazku
	    if ( defined $speak) {
            speak $speak;
            i_said($speak);
	    } else {
            speak next_question_prompt();
	    }
	#}
}

sub initialize {
    $reply_count = 0;
    @greeting_use = init_use(scalar @greeting_use);
    @nothing_to_say_use = init_use(scalar @nothing_to_say_use);
    @next_question_prompt_use = init_use(scalar @next_question_prompt_use);
    @end_dialogue_use = init_use(scalar @end_dialogue_use);
    @too_short_use = init_use(scalar @end_dialogue_use);
    @repeat_yourself_use = init_use(scalar @repeat_yourself_use);
    @angry_use = init_use(scalar @angry_use);
    @kolega_use = init_use(scalar @kolega_use);
    @noun_blank_use = init_use(scalar @noun_blank_use);
    @praise_use = init_use(scalar @praise_use);
    @no_question_use = init_use(scalar @no_question_use);

    %told_ya = ();
    %told_me = ();

    @soutez_use = init_use(scalar @soutez_use);
    @name_use = init_use(scalar @name_use);
    @place_use = init_use(scalar @place_use);
    @akce_use = init_use(scalar @akce_use);
    @vysledek_use = init_use(scalar @vysledek_use);
    @fans_use = init_use(scalar @fans_use);
    @hrac_use = init_use(scalar @hrac_use);
}

$scenario->end();
close $logfile;