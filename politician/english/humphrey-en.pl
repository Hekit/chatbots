#!/usr/bin/perl

print "### Started, doing setup ###\n";

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

#say @INC;


# konstanty
my $prob_typo = 0; # it is 0-100 < typo
my $prob_praise = 25; # similarly

my $reply_count = 0;
my $cycle = 0;
my $cyc_lim = 25;

my $keyword = "";
my $key_colour = 5;
my %keys;

sub speak {
    my ($line) = @_;

    say "Humphrey: " . $line;
    say $logfile $line;
    
    u_said($line);
    print "> ";

    return;
}

sub run_dialogue
{
    initialize();
    machine_talks();
}

sub machine_talks {
    respond(); 
    while($line = <>)
    {
        if ($line eq ":q\n") {
            exit 0;
        }
        if ($line eq ":s\n") {
            # start interview from beggining
        }
        print "> ", $line;
        $reply_count += 1;
        #say "waiting for ENTER";
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

# basic answers
my @greeting = (
    "Greetings!"
	);
my @greeting_use = init_use(scalar @greeting);

my @nothing_to_say = (
	"Next question, please.", 
	"No comment.");
my @nothing_to_say_use = init_use(scalar @nothing_to_say);

my @next_question_prompt = (
	"What are you interested in?",
	"Pose your question, please.",
    "I believe you have a question?");
my @next_question_prompt_use = init_use(scalar @next_question_prompt);

my @end_dialogue = (
	"That should be enough for now.", 
	"I am sorry but I have to go, the canteen will is going to close soon.",
    "Oh, it is so late! I am sorry, but I have to leave.",
    "I am sorry, but I have to go, I have an important appointment scheduled.",
    "I have to go, I have a TV interview to attend.");
my @end_dialogue_use = init_use(scalar @end_dialogue);

my @too_short = (
	"I would really like to tell you something clever, but now there's really nothing to reply to. Please try harder.",
	"Please try to pose real questions, since I am already wasting my precious time with you.",
    "You're not paid by letter count, are you? Try something a bit longer anyway, please.");
my @too_short_use = init_use(scalar @too_short);

my @repeat_yourself = (
    "Could you try to change your question at least a little bit? This is boring.",
    "A little change is also a change, so maybe try some."
    );
my @repeat_yourself_use = init_use(scalar @repeat_yourself);

my @angry = (
    "I am very sorry but I am not here for your entertainment.",
    "Look, we cannot continue like this."
    );
my @angry_use = init_use(scalar @angry);

my @colleague = (
    "Smith", "Brown", "Watson", "Johnson"
    );
my @colleague_use = init_use(scalar @colleague);

my @noun_blank = (
    "It is a very pressing issue.",
    "We will focus on this topic in the next election campaign.",
    "This topic has been and will be the subject of many discussions, therefore I cannot tell you any details at this moment.",
    "I did a thorough analysis of these problems in my press release yesterday, so I will comment it no more.",
    "You ask about things that are highly confidential. You cannot be surprised that I am not going to answer.",
    "I hope you do not really expect me to answer such question.",
    );
my @noun_blank_use = init_use(scalar @noun_blank);

my @praise = (
    "Your question show your deep understanding of this topic. They are clearly of high interest for you.",
    "That is a good question.",
    "That is a very good question.",
    "That is a brilliant question."
    );
my @praise_use = init_use(scalar @praise);

my @no_question = (
    "Were those really all your questions?",
    "Are you sure you want to ask no more?",
    "Anything else you are curious about ... ?",
    "Please, check your todo list if there is anything else you need to ask about."
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

sub colleague {
    if (usage_ok(@colleague_use) == 0) {
        for my $i (0..scalar(@colleague_use)-1) {
            $colleague_use[$i] = 0;
        }
    }
    my $idx;
    do {
        $idx = rand(scalar(@colleague_use));
    } while ($colleague_use[$idx] == 1);
    $colleague_use[$idx] = 1;
    return $colleague[$idx];
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


my @keywords;

open(my $f_keywords, '<:encoding(UTF-8)', "keywords")
 or die "Couldn't open database of keywords";

while (my $row = <$f_keywords>) {
    chomp $row;
    push(@keywords, $row);
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
		#CZ this is obviously a czech thingy - the verbs need to be changed so that meaningless verbs are excluded
        if ( $anode->tag =~ /^V/ && $anode->lemma !~ /být|mít|žít/) {
            $node = $anode;
        }
    }
    return $node;
}

sub find_words {
    my @anodes = @_;
    @words = ();
    foreach my $anode (@anodes) {
        push(@words, $anode->lemma);
    }
}

my %told_ya = ();
my %told_me = ();

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
        if ($subpos eq "i") { #verb is in imperative
            return 1;
        }
    }
    return 0;
}

sub typo {
    my $sentence = shift;

    my $prob = int(rand(100));
    ### setting typo probability
    if ($prob < $prob_typo){
        my $idx = int(rand(length($sentence)-4)) + 2;
        my $old = $sentence;
        $sentence = substr $old, 0, $idx;
        $sentence = $sentence . substr $old, $idx+1, 1;
        $sentence = $sentence . substr $old, $idx, 1;
        $sentence = $sentence . substr $old, $idx+2, length($old)-$idx; 
    }
    return $sentence; 
}

# dialogue methods

my $last_was_q;

### NOT IN USE (but could be)
#CZ all of it (jaky = what)
sub what {
    my ($anodes) = @_;

    my $speak;
    my $noun = find_last_noun($anodes);
    if (defined $noun) {
        my $gender = get_tag_cat($noun->tag, 'gender');
        my $number = get_tag_cat($noun->tag, 'number');

        my $jakytag = 'P4YS4----------';
        $jakytag = set_tag_cat($jakytag, 'gender', $gender);
        $jakytag = set_tag_cat($jakytag, 'number', $number);

		my $jaky = ucfirst $generator->get_form('jaký', $jakytag);

        my $byltag = 'VpYS---XR-AA---';
        $byltag = set_tag_cat($byltag, 'gender', $gender);
        $byltag = set_tag_cat($byltag, 'number', $number);
        my $byl = $generator->get_form('být', $byltag);

        my $tag1 = set_tag_cat($noun->tag, 'case', '4');
        my $form = $generator->get_form($noun->lemma, $tag1);

        if ( $jaky && $byl && $form) {
            $speak = "$jaky $form máte na mysli?";
            #$answer_to = $noun->lemma;
        }
    }
    return $speak;
}

### also not in use
#CZ good part of it
sub why {
    my ($anodes) = @_;

    my $speak;
    my $node = find_last_full_verb($anodes);
    if ( defined $node ) {#&& !defined $info{$node->lemma}) {
        my $form = lc $node->form;
        $speak = "Why $form?";
        #$answer_to = $node->lemma;
    }

    return $speak;
}


# opinion
#CZ words obviously need to be adjusted - to think, to believe, a belief, ...
my @opinion_verbs = ("myslet", "myslit", "myslit_:T", "říkat_:T");
my @opinion_nouns = ("názor", "dojem");

#CZ
sub opinion {
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
					#CZ My [keyword] is following the party's line
                    when(0) {$speak = "Můj " . $node . " je zcela v souladu se stranickou linií.";}
                    #CZ I do not think anything like that would matter
					when(1) {$speak = "Nemyslím si, že na něčem takovém by záleželo.";}
                }
            }
            if ($what eq "v") {
                given (int(rand(2))) {
					#CZ Reviewing this topic is unfortunately beyond my expertise / competence
                    when(0) { $speak = "Hodnocení tohoto tématu je bohužel mimo moji kompetenci.";}
					#CZ I think that everything follows the party's line
                    when(1) { $speak = "Myslím, že vše je v souladu se stranickou linií.";}
                }
            }
            $cyc_const++;
        } while (exists $told_ya{$speak} && $cyc_const < $cyc_lim)
    }
    if ($cyc_const >= $cyc_lim) {return undef;}
    else {return $speak;}
}

my @keyword_use = init_use(11);
sub keyword {
    my ($anodes) = @_;
    my $speak;
    my $node;
    my $done = 0;

    foreach my $keyword (@keywords) {
         if ($keyword ~~ @nouns) {
            
            foreach my $anode (@$anodes) {
                if ($anode->lemma eq $keyword) {
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
            $used = int(rand(11));
            given ($used) {
                when(0) {
                    my $tag1 = set_tag_cat($node->tag, 'case', '1');
                    my $form = lcfirst $generator->get_form($node->lemma, $tag1);
                    
                    my $nezajima_tag = 'VB-S---3P-NA---';
                    $nezajima_tag = set_tag_cat($nezajima_tag, 'number', $number);
                    my $nezajima = lcfirst $generator->get_form('zajímat', $nezajima_tag);
					#CZ I am not interested in [keyword], but I am sure we will discuss it during the government meeting
                    $speak = "Mě " . $form . " " . $nezajima . 
                            ", ale jsem si jist, že to na vládě důkladně projednáme.";
                    $key_colour = 1;
                }
                when(1) {
                    my $tag1 = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag1);

                    my $byt_tag = 'VB-----3P-AA---';
                    $byt_tag = set_tag_cat($byt_tag, 'number', $number);
                    my $byt = lcfirst $generator->get_form('být', $byt_tag);

                    my $dulezity_tag = 'AA--1----1A----';
                    $dulezity_tag = set_tag_cat($dulezity_tag, 'number', $number);
                    $dulezity_tag = set_tag_cat($dulezity_tag, 'gender', $gender);
                    my $dulezity = lcfirst $generator->get_form('důležitý', $dulezity_tag);
                    #CZ [keyword] is important, but we have to look at the whole problem from a global perspective, too
					$speak = $form . " " . $byt . " sice " . $dulezity . 
                            ", ale musíme se na celý problém podívat z globální perspektivy.";
                    $key_colour = 2;
                }
                when(3) {
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = lcfirst $generator->get_form($node->lemma, $tag);
					#CZ I do not think that [keyword] is one of the most pressing issues
                    $speak = "Nemyslím si, že " . $form . " patří k nejpalčivějším tématům.";
                    $key_colour = 3;
                }
                when(4) {
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
					#CZ [keyword] is not our priority during these elections
                    $speak = $form . " nepatří v tomto volebním období k našim prioritám.";
                    $key_colour = 3;
                }
                when(5) {
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);

                    my $byt_tag = 'VB-----3P-AA---';
                    $byt_tag = set_tag_cat($byt_tag, 'number', $number);
                    my $byt = lcfirst $generator->get_form('být', $byt_tag);

                    my $plod_tag = 'NNI-7-----A----';
                    $plod_tag = set_tag_cat($plod_tag, 'number', $number);
                    my $plod = lcfirst $generator->get_form('plod', $plod_tag);

					#CZ [keyword] is/are the fruit(s) of our efforts in many years
                    $speak = $form . " " . $byt . " " . $plod . " našeho mnohaletého úsilí.";
                    $key_colour = 4;
                }
                when(6) {
                    my $tag = set_tag_cat($node->tag, 'case', '4');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
                    my $pronoun_tag = 'P5--3--3-------';
                    my $pronoun;
                    $pronoun_tag = set_tag_cat($pronoun_tag, 'number', $number);
                    $pronoun_tag = set_tag_cat($pronoun_tag, 'gender', $gender);
                    $pronoun = lcfirst $generator->get_form('on-1', $pronoun_tag);

					#CZ We analyzed [keyword] during yesterday's party meeting and before I learn the official view, I cannot give any comments
                    $speak = $form . " jsme rozebírali na včerejší schůzi a dokud se nedozvím "
                    . "stanovisko vedení strany, nemohu se k " . $pronoun . " vyjadřovat.";
                    $key_colour = 2;
                }                
                when(7) {
                    my $tag = set_tag_cat($node->tag, 'case', '2');
                    my $form = lcfirst $generator->get_form($node->lemma, $tag);
                    #CZ Mr. [colleague] is most knowledgable in our party on the topic of [keyword], I can redirect you to him
					$speak = "Problematikou " . $form . " se v našem poslaneckém klubu zabývá " .
                    "kolega " . colleague() . ". Já vás jen mohu odkázat na něj.";         
                    $key_colour = 1;           
                }
                when(8) {
                    my $tag = set_tag_cat($node->tag, 'case', '7');
                    my $form = lcfirst $generator->get_form($node->lemma, $tag);
					#CZ We have already agreed upon preparing a special comittee to deal with [keyword]. Let us wait for their results
                    $speak = "Už jsme odhlasovali vytvoření speciální komise, která se bude " . $form 
                    . " zabývat. Počkejme si na její závěry.";
                    $key_colour = 1;
                }
                when (9) {
                    my $tag = set_tag_cat($node->tag, 'case', '2');
                    my $form = lcfirst $generator->get_form($node->lemma, $tag);
					#CZ I have no right to comment on [keyword]
                    $speak = "Nemám mandát se na téma " . $form . " vyjadřovat.";
                    $key_colour = 2;
                }
                when (10) {
                    my $tag = set_tag_cat($node->tag, 'case', '4');
                    my $form = lcfirst $generator->get_form($node->lemma, $tag);
                    my $nep_tag = 'AA--4----1N----';
                    my $nepodstatne;
                    $nep_tag = set_tag_cat($nep_tag, 'number', $number);
                    $nep_tag = set_tag_cat($nep_tag, 'gender', $gender);
                    $nepodstatne = lcfirst $generator->get_form('podstatný', $nep_tag);
					#CZ Seeing a greater perspective of current problems I do not consider [keyword] to be of any importance
                    $speak = "Vzhledem k současným problémům považuji " . $form 
                    . " za " . $nepodstatne . ".";
                    $key_colour = 3;
                }
            }
            $cyc_const++;
        } while ( @keyword_use[$used]==1 && $cyc_const < $cyc_lim);
        $keyword = $node->lemma;
        if (!defined $keys{$keyword} || $keys{$keyword} == $key_colour) {
            @keyword_use[$used] = 1;
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

my @name_use = init_use(8);
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
                    #CZ I do not like this person at all
					$speak = "Tohohle člověka vůbec nemám rád.";
                    $key_colour = 1;
                }
                when (1) {
                    my $tag = set_tag_cat($name->tag, 'case', '2');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
                    #CZ We value [person] the most when he is not talking
					$speak = $form . " si vážíme nejvíce když mlčí.";
                    $key_colour = 1;
                }
                when (2) {
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
					#CZ [person] is the right person in the right spot
                    $speak = $form . " je člověk na svém místě.";
                    $key_colour = 2;
                }
                when (3) {                                                                                                                                                                                                                                                                                              
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
					#CZ [person] has my full support
                    $speak = $form . " má mou plnou podporu.";
                    $key_colour = 2;
                }
                when (4) {
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
					#CZ [person] needs professional help
                    $speak = $form . " potřebuje odbornou pomoc.";
                    $key_colour = 1;
                }
                when (5) {
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
					#CZ [person] is my big (cant think of the word - when you look up to someone)
                    $speak = $form . " je můj velký vzor.";
                    $key_colour = 2;
                }
                when (6) {
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
					#CZ [person] is very inspiring for me
                    $speak = $form . " je pro mě velkou inspirací.";
                    $key_colour = 2;
                }
            }
        $cyc_const++;
        } while (@name_use[$used]==1 && $cyc_const < $cyc_lim);
        $keyword = $name->lemma;
        if (!defined $keys{$keyword} || $keys{$keyword} == $key_colour) {
            @name_use[$used] = 1;
        }
        if ($cyc_const >= $cyc_lim) { return undef; }
        else {$keyword = $name->lemma;}
    }
    return $speak;
}

my @place_use = init_use(8);
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
            $used = int(rand(8));
            given ($used) {
                when (0) {
					#CZ I have never been there
                    $speak = "Tam jsem nikdy nebyl.";
                    $key_colour = 3;
                }
                when (1) {
                    my $tag = set_tag_cat($place->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
					#CZ [place] is a really nice place. I like to go there to relax
                    $speak = $form . " je moc hezké místo. Rád si tam jezdím odpočinout.";
                    $key_colour = 2;
                }
                when (2) {
                    my $tag = set_tag_cat($place->tag, 'case', '6');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
					#CZ [place] is wonderful in spring. I like it a lot there.
                    $speak = "V " . $form . " bývá zjara krásně. Moc se mi tam líbí.";
                    $key_colour = 2;
                }
                when (3) {
                    my $tag = set_tag_cat($place->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
					#CZ Oooh, [place], I drew through once several years ago
                    $speak = "Jó, " . $form . ", tamtudy už jsem jednou před lety projížděl.";
                    $key_colour = 4;
                }
                when (4) {
                    my $tag = set_tag_cat($place->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
					#CZ You can hardly find a more boring place than [place]
                    $speak = "Podle mě těžko najdete větší díru než " . $form . ".";
                    $key_colour = 1;
                }
                when (5) {
                    my $tag = set_tag_cat($place->tag, 'case', '6');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
					#CZ I have a public discussion in [place] next week
                    $speak = "V " . $form . " příští týden pořádám besedu.";
                    $key_colour = 3;
                }
                when (6) {
                    my $tag = set_tag_cat($place->tag, 'case', '2');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
					#CZ I plan to go to [place] for a work-trip to be able to better judge their competency
                    $speak = "Do " . $form . " se chystám na služební cestu, abych tamní situaci dokázal kompetentně posoudit.";
                    $key_colour = 4;
                }
                when (7) {
                    my $tag = set_tag_cat($place->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
					#CZ [place] has its own issued that we cannot understand here
                    $speak = $form . " má své vlastní problémy, které my zde nedokážeme posoudit.";
                    $key_colour = 4;
                }
            }
        $cyc_const++;
        } while ( @place_use[$used]==1 && $cyc_const < $cyc_lim);
        $keyword = $place->lemma;
        if (!defined $keys{$keyword} || $keys{$keyword} == $key_colour) {
            @place_use[$used] = 1;
        }
        if ($cyc_const >= $cyc_lim) { return undef; }
        else {$keyword = $place->lemma;}
    }
    return $speak;
}

sub intro { #CZ This will probably be the toughest. It should deal with 'how are you' and stuff, with 42, with asking for name, ... enjoy :))
    my ($anodes) = @_;
    my $speak;

    if ("jak-3" ~~ @words && "se_^(zvr._zájmeno/částice)" ~~ @words) {

        if ("mít" ~~ @words) {
            $speak = "Mám se výtečně, děkuji za optání.";
            return $speak;
        } 
        if ("dařit_:T" ~~ @words) {
            $speak = "Daří se mi skvěle, díky!";
            return $speak;
        }
        if ("jmenovat_:T_:W" ~~ @words) {
            $speak = "Mé jméno je Humphrey Novotný.";
            return $speak;
        }
    }
    if ("kolik" ~~ @words && "rok" ~~ @words && "ty" ~~ @words) {
        $speak = "Jednadvacet už mi bylo a dál je to moje věc.";
        return $speak;
    }
    if ("jaký" ~~ @words && "věk" ~~ @words && "tvůj_^(přivlast.)" ~~ @words) {
        $speak = "Jednadvacet už mi bylo a dál je to moje věc.";
        return $speak;
    }
    if ("život" ~~ @words && "vesmír" ~~ @words) {
        $speak = "42.";
        return $speak;
    }

    return $speak;
}


# guiding mechanism
my $logname = strftime("%Y-%m-%d_%H-%M-%S.log", localtime(time));
open $logfile, '>:utf8', $logname;
	
#print $client "Session initialized.\n";
&run_dialogue();

sub reply_hierarchy {
    my @ar = @_;
    my $speak = "";
    
    do {
    $speak = intro(@ar);
    $keyword = "";
    if (!defined $speak || length($speak) <= 0) {
		$speak = name(@ar);
		if (!defined $speak || length($speak) <= 0) {
			$speak = place(@ar);
			if (!defined $speak || length($speak) <= 0) {
				$speak = opinion(@ar);
				$keyword = "";
				if (!defined $speak || length($speak) <= 0) {
					$speak = keyword(@ar);
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
	
        my $prob = int(rand(100));
        if ($prob <= $prob_praise) {
            $speak = praise() . " " . $speak;
        }
    }
    say "keyword ". $keyword;
    say $keys{$keyword};
    say "key_col ". $key_colour;
    #say defined $keys{$keyword};
    } while (defined $keys{$keyword} && $keys{$keyword} != $key_colour);
    #say $keyword;
    #say $keys{$keyword};
    if (!defined $keys{$keyword} && length($keyword)>1) {
        say "ukladam " . $keyword;
        $keys{$keyword} = $key_colour;
    }
    $speak = typo($speak);

    #foreach $a (@pojem_use){
    #print $a;      
    #}
    #say;

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
		# repeats identical question
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

	# the sentence is too short -> we ask for a longer one
	    if ( @anodes == 0 ) {
            speak too_short();
            return;
	    }

        if (! $last_was_q) {
            speak no_question();
            return;
        }
    # main reply mechanism
        my $speak = reply_hierarchy(\@anodes);
	# if it produced something, then just say it, if not, ask for another question
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
    @colleague_use = init_use(scalar @colleague_use);
    @noun_blank_use = init_use(scalar @noun_blank_use);
    @praise_use = init_use(scalar @praise_use);
    @no_question_use = init_use(scalar @no_question_use);

    %told_ya = ();
    %told_me = ();

    @pojem_use = init_use(scalar @pojem_use);
    @name_use = init_use(scalar @name_use);
    @place_use = init_use(scalar @place_use);
}

$scenario->end();
close $logfile;