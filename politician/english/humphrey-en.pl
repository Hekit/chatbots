#!/usr/bin/perl5

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
use Treex::Tool::EnglishMorpho::Lemmatizer;

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
my $pst_typo = 0; # je to 0-100 < typo
my $pst_pochvala = 25; # obdobne

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

sub machine_talks {
    respond();
    while($line = <>)
    {
        if ($line eq ":q\n") {
            exit 0;
        }
        if ($line eq ":s\n") {
            # zacit rozhovor odznova
        }
        print "> ", $line;
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
    "Greetings."
	);
my @greeting_use = init_use(scalar @greeting);

my @nothing_to_say = (
	"Next question, please.",
	"No comment.",
	"I will not address this subject.",
	"I will refrain from commenting on this subject",
	"I wish I could enlighten you on this subject, but I can't.");
my @nothing_to_say_use = init_use(scalar @nothing_to_say);

my @next_question_prompt = (
	"What are you interested in?",
	"Pose your question, please.",
    "I believe you have a question for me.",
    "What would you like to discuss about?");
my @next_question_prompt_use = init_use(scalar @next_question_prompt);

my @end_dialogue = (
	"That should be enough for now.",
	"I am terribly sorry but I have to go, have a meeting that starts in 10 minutes.",
    "Oh, it is already late! I am sorry, but I have to leave.",
    "Please excuse me but I have to go, I have an important appointment scheduled.",
    "I have to go, I have a TV interview to attend.",
    "It has been a pleasure talking ot you, but I'm afraid I have to leave.",
    "Unfortunately I need to leave, but please call my office to arrange a meeting with me soon.");
my @end_dialogue_use = init_use(scalar @end_dialogue);

my @too_short = (
	#"I would really like to tell you something clever, but now there's really nothing to reply to. Please try harder.",
	#"Please try to pose real questions, since I am already wasting my precious time with you.",
    "You're not paid by letter count, are you? Try something a bit longer, please.",
    "Could you please elaborate a bit more on this topic?",
    "I'm sorry, could you be a bit more specific?",
    "I didn't quite understand that, would you mind rephrasing your question?");
my @too_short_use = init_use(scalar @too_short);

my @repeat_yourself = (
    "Could you repeat your question, please?",
    "I'm sorry, my phone rang, could you please repeat the question?",
    "I didn't get that, can you repeat the question?"
    );
my @repeat_yourself_use = init_use(scalar @repeat_yourself);

my @angry = (
    "I am very sorry but I will not entertain this.",
    "We cannot continue talking on this subject.",
    "Are you delibarately trying to embarrass me?",
    "My position is clear, I do not stand for this. Let's change the subject.",
    "Let's keep this a civilized setting and move to another subject.",
    "Are you working for our opponents?",
    "This rhetoric will not be tolerated."
    );
my @angry_use = init_use(scalar @angry);

my @colleague = (
    "Thater", "Brown", "Watson", "Johnson", "Nelson", "Renslow", "Peters", "Jones", "Montalbani", "Sayeed", "Dehdari"
    );
my @colleague_use = init_use(scalar @colleague);

my @noun_blank = (
    "This is a very pressing issue.",
    "We will focus on this topic in the next election campaign.",
    "This topic has been and will be the subject of many discussions, and we are preparing a proposal for the next parliament session. Therefore I cannot tell you any details at this moment.",
    "I did a thorough analysis of these problems in my press release yesterday, so I will comment it no more.",
    "You ask about things that are highly confidential. You cannot be surprised that I am not going to answer.",
    "I would prefer to refrain from commenting on this topic, for the time being.",
    );
my @noun_blank_use = init_use(scalar @noun_blank);

my @praise = (
    "Your question shows your deep understanding of this topic. This is clearly of high interest for you.",
    "That is a good question.",
    "That is a very good question.",
    "That is a brilliant question.",
    "I am very glad you brought this subject up.",
    "I too have found this topic very interesting.",
    "First of all, allow me to say that I share the same passion for this issue.",
    "Thank you for bringing this important issue to light.",
    "Very good point."
    );
my @praise_use = init_use(scalar @praise);

my @no_question = (
    "Were those really all your questions?",
    "Are you sure you don't have any more questions?",
    "Anything else you are curious to know?",
    #"Please, check your todo list if there is anything else you need to ask about."
    "Could I help you with anything else?",
    "Let me know if you need clarificiations on anything."
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
 or die "Couldn't open database2";

while (my $row = <$f_keywords>) {
    chomp $row;
    push(@keywords, $row);
}



# init

    #Util::SetGlobal language=cs
    #W2A::CS::Tokenize
    #W2A::CS::TagMorphoDiTa lemmatize=1

my $scenario_string = '
    Util::SetGlobal language=en
    W2A::EN::Tokenize
    W2A::EN::TagMorphoDiTa
    W2A::EN::Lemmatize
';

my $scenario = Treex::Core::Scenario->new(from_string => $scenario_string);
$scenario->start();

use Treex::Tool::Depfix::FormGenerator;
my $generator = Treex::Tool::Depfix::FormGenerator->new();

sub create_document_from_sentence {
    my ($sentence) = @_;

    use Treex::Core::Document;
    my $document = Treex::Core::Document->new();
    my $bundle = $document->create_bundle();
    my $zone = $bundle->create_zone('en');
    $zone->set_sentence($sentence);

    return $document;
}

use Treex::Block::W2A::EN::TagMorphoDiTa;
sub set_tag_cat {
    my ($tag, $cat, $value) = @_;

    return Treex::Block::W2A::EN::TagMorphoDiTa::set_tag_cat($tag, $cat, $value);
}
sub get_tag_cat {
    my ($tag, $cat) = @_;

    return Treex::Block::W2A::EN::TagMorphoDiTa::get_tag_cat($tag, $cat);
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
	   if ( $anode->tag =~ /NN/) {
	        push(@nouns, $anode->lemma);
    	}
    }
}

sub find_adjectives {
    my @anodes = @_;
    @adjectives = ();
    foreach my $anode (@anodes) {
	   if ( $anode->tag =~ /JJ/) {
	        push(@adjectives, $anode->lemma);
	   }
    }
}

sub find_verbs {
    my @anodes = @_;
    @verbs = ();
    foreach my $anode (@anodes) {
	   if ( $anode->tag =~ /VVP/) { #maybe needs more
	        push(@verbs, $anode->lemma);
    	}
    }
}

sub find_last_noun {
    my ($anodes) = @_;
    my $node;
    foreach my $anode (@$anodes) {
        # speak ($anode->form . " " . $anode->lemma . " " . $anode->tag );
        if ( $anode->tag =~ /NP/) {
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
        if ( $anode->tag =~ /JJ/) {
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
        if ( $anode->tag =~ /^V/ && $anode->lemma !~ /be|have|do/) {
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
        #my $subpos = get_tag_cat($anode->tag, 'subpos');
        #if ($subpos eq "i") { #verb is in imperative
        #    return 1;
        #}
    }
    return 0;
}

sub typo {
    my $sentence = shift;

    my $pst = int(rand(100));
    ### setting typo probability
    if ($pst < $pst_typo){
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

### momentalne se nepouziva, nema to totiz moc velke vyuziti
sub what {
    my ($anodes) = @_;

    my $speak;
    my $noun = find_last_noun($anodes);
    if (defined $noun) {
        my $gender = get_tag_cat($noun->tag, 'gender');
        my $number = get_tag_cat($noun->tag, 'number');

        my $whattag = 'P4YS4----------';
        $whattag = set_tag_cat($whattag, 'gender', $gender);
        $whattag = set_tag_cat($whattag, 'number', $number);
        my $what = ucfirst $generator->get_form('what', $whattag);

        my $byltag = 'VpYS---XR-AA---';
        $byltag = set_tag_cat($byltag, 'gender', $gender);
        $byltag = set_tag_cat($byltag, 'number', $number);
        my $byl = $generator->get_form('be', $byltag);

        my $tag1 = set_tag_cat($noun->tag, 'case', '1');
        my $form = $generator->get_form($noun->lemma, $tag1);

        if ( $what && $byl && $form) {
            $speak = "$what $form do you mean?";
            #$answer_to = $noun->lemma;
        }
    }
    return $speak;
}

### momentalne se nepouziva, nema to totiz moc velke vyuziti
sub proc {
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


# sub pro nazor
my @opinion_verbs = ("think", "believe", "claim", "feel", "consider", "bemuse");
my @opinion_nouns = ("opinion", "impression", "belief", "judgement", "thinking", "point", "view", "viewpoint", "perspective");

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
                    when(0) {$speak = "My " . $node . " is completely in accordance with our party ideals.";}
                    when(1) {$speak = "In my opinion, this is not a pressing matter";}
                }
            }
            if ($what eq "v") {
                given (int(rand(2))) {
                    when(0) { $speak = "Unfortunately, the evaluation of this topic is beyond my competence.";}
                    when(1) { $speak = "I think everything adheres to the beliefs of my party.";}
                }
            }
            $cyc_const++;
        } while (exists $told_ya{$speak} && $cyc_const < $cyc_lim)
    }
    if ($cyc_const >= $cyc_lim) {return undef;}
    else {return $speak;}
}

my @did_use = init_use(2);
sub did {
    my ($anodes) = @_;
    my $speak = undef;
    my $node = undef;

    foreach my $verb (@verbs) {
        if ($verb->lemma eq "do") { # make sure the lemma indeed is "do"
            $node = "ok";
            last;
       }
    }

    my $cyc_const = 0;

    if (defined $node) {
        my $used = -1;
        do {
            $used = int(rand(2));
            given ($used) {
                when (0) {
                    $speak = "That is a matter of times long gone.";
                }
                when (1) {
                    $speak = "There is no reason to bring up this topic now, after such time.";
                }
            }
            $cyc_const++;
        } while ( @did_use[$used]==1 && $cyc_const < $cyc_lim);
        @did_use[$used] = 1;
    }

    if ($cyc_const >= $cyc_lim) {
        return undef;
    } else {
        if (defined $node) {$keyword = $node->lemma;}
        return $speak;
    }
}

my @pojem_use = init_use(21);
sub pojem {
    my ($anodes) = @_;
    my $speak;
    my $node;
    my $done = 0;

    foreach my $pojem (@keywords) {
         if ($pojem ~~ @nouns) {

            foreach my $anode (@$anodes) {
                if ($anode->lemma eq $pojem) {
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
            $used = int(rand(21));
            given ($used) {
                when(0) {
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);

                    $speak = "I am not fully qualified to speak about " . $form .
                            ", but I am certain that we will discuss it thoroughly in the next party meeting with my peers.";
                    $key_colour = 1;
                }
                when(1) { # WORKS!
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
                    $speak = "The issue of ". $form . " is very important, but it would be wiser to look at this topic from a wider perspective.";
                    $key_colour = 2;
                }
                when(3) { # Broken
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
                    $speak = "I do not think that  " . $form . " is one of the most burning issues.";
                    $key_colour = 3;
                }
                when(4) { # broken
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
                    $speak = $form . " is not one of our priorities in this election period, since we are preoccupied with many more issues that demand our undivided attention.";
                    $key_colour = 3;
                }
                when(5) { #broken
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
                    $speak = $form . " is the result of our many years of joined effort, and we aim for a quick resolution.";
                    $key_colour = 4;
                }
                when(6) {
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
                    my $pronoun_tag = 'P5--3--3-------';
                    my $pronoun;
                    $pronoun_tag = set_tag_cat($pronoun_tag, 'number', $number);
                    $pronoun_tag = set_tag_cat($pronoun_tag, 'gender', $gender);
                    $pronoun = ucfirst $generator->get_form('on-1', $pronoun_tag);

                    $speak = $form . " this has been discussed in yesterday's party meeting and if I do not know "
                    . "the opinion of the party leadership, " . $pronoun . " cannot express.";
                    $key_colour = 2;
                }
                when(7) { #broken
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
                    $speak = "The issue of " . $form . " is one of our political party's concerns. " .
                    "My colleague " . colleague() . " is more aware of the topic and I will be happy to transfer your concerns.";
                    $key_colour = 1;
                }
                when(8) { #WORKS!
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
                    $speak = "We have already agreed to form a special comittee, in order to deal with the issue of " . $form
                    . ". We can hope to come up with viable solutions and implement them as soon as possible.";
                    $key_colour = 1;
                }
                when (9) {
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
                    $speak = "I have no right to comment on " . $form . ". This falls past my jurisdiction.";
                    $key_colour = 2;
                }
                when (10) {
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
                    $speak = "Seeing as there are current events that are calling for immediate action, I consider " . $form
                    . " to be not as pressing as those.";
                    $key_colour = 3;
                }
                when (11) { #WORKS
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
                    $speak = $form
                    . " has been one of of the main focus points in the party's agenda, and we are working tirelessly to solve it.";
                    $key_colour = 4;
                }
                when (12) { #broken
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
                    $speak = "Our opponents have openly supported " . $form
                    . " but we want to remind the public that we have actually taken action.";
                    $key_colour = 1;
                }
                when (13) {
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
                    $speak = "Seeing as there are current events that are calling for immediate action, I consider " . $form
                    . " to be not as pressing as those.";
                    $key_colour = 3;
                }
                when (14) { #BROKEN
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
                    $speak = "Since my first campaign, I have made " . $form
                    . " one of my personal problems to tackle, and I can assure you I am still involved.";
                    $key_colour = 4;
                }
                when (15) { #broken
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
                    $speak = "I am profloundly unhappy with the way " . $form
                    . " is dealt with. I hope in the future we will be able to have a better plan.";
                    $key_colour = 4;
                }
                when (16) { #broken
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
                    $speak = "I have not addressed the issue of " . $form
                    . " for good reason; our priorities for the moment lie elsewhere.";
                    $key_colour = 4;
                }
                when (17) { #broken
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
                    $speak = "My background is not ideal for me to speak about " . $form
                    . " but my colleague " . colleague() . " is ideal for that conversation." ;
                    $key_colour = 4;
                }
                when (18) {
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
                    $speak = "It's not appropriate to talk about " . $form
                    . " when our nation is being challenged with graver issues." ;
                    $key_colour = 4;
                }
                when (19) {
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
                    $speak = "It would not be wise of me to talk about " . $form
                    . " without addressing more pressing issues first." ;
                    $key_colour = 4;
                }
                when (20) { # broken
                    my $tag = set_tag_cat($node->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($node->lemma, $tag);
                    $speak = "One of our party's goals for the next year is to fight " . $form
                    . " in any way possible." ;
                    $key_colour = 4;
                }

            }
            $cyc_const++;
        } while ( @pojem_use[$used]==1 && $cyc_const < $cyc_lim);
        $keyword = $node->lemma;
        if (!defined $keys{$keyword} || $keys{$keyword} == $key_colour) {
            @pojem_use[$used] = 1;
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
            $used = int(rand(8));
            given ($used) {
                when (0) {
                    $speak = "I am not pleased with this person's last statements.";
                    $key_colour = 1;
                }
                when (1) {
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
                    $speak = $form . " is mostly valuable when silent.";
                    $key_colour = 1;
                }
                when (2) {
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
                    $speak = $form . " is excellent for their position and a person I personally admire.";
                    $key_colour = 2;
                }
                when (3) {
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
                    $speak = $form . " has my full support.";
                    $key_colour = 2;
                }
                when (4) {
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
                    $speak = $form . " could use some professional help.";
                    $key_colour = 1;
                }
                when (5) {
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
                    $speak = $form . " serves as a personal inspiration to me and I can only aspire to follow in their footsteps.";
                    $key_colour = 2;
                }
                when (6) {
                    $speak = "Hm, I'd rather not say...";
                    $key_colour = 2;
                }
                when (7) {
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
                    $speak = $form . " is a great inspiration to me. Their contribution to the world is remarkable.";
                    $key_colour = 2;
                }
                when (8) {
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
                    $speak = "I am appaled by " . $form . "'s recent statemens.";
                    $key_colour = 2;
                }
                when (9) {
                    $speak = "I do not want to associate myself with such a person, not even in this conversation.";
                    $key_colour = 2;
                }
                when (10) {
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
                    $speak = "I am astounded by the initiative and the community work " . $form . " does.";
                    $key_colour = 2;
                }
                when (11) {
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
                    $speak = "I cannot bring myself to say anything nice about " . $form . ".";
                    $key_colour = 2;
                }
                when (12) {
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
                    $speak = "I won't say anything about " . $form . "; the facts speak for themselves.";
                    $key_colour = 2;
                }
                when (13) {
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
                    $speak = "I wish " . $form . " would talk less and act more.";
                    $key_colour = 2;
                }
                when (14) {
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
                    $speak = "I have a lifelong frinedship with " . $form . " and I am glad for that.";
                    $key_colour = 2;
                }
                when (15) {
                    my $tag = set_tag_cat($name->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($name->lemma, $tag);
                    $speak = "The work of " . $form . " is truly remarkable.";
                    $key_colour = 2;
                }
                when (16) {
                    $speak = "I will refrain from commenting.";
                    $key_colour = 2;
                }
                when (17) {
                    $speak = "I am appalled such a person exists.";
                    $key_colour = 2;
                }
                when (18) {
                    $speak = "Who is this?";
                    $key_colour = 2;
                }
                when (19) {
                    $speak = "I have never heard of a person with that name.";
                    $key_colour = 2;
                }
                when (20) {
                    $speak = "I will not be associated with criminals.";
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
                    $speak = "I have never been there.";
                    $key_colour = 3;
                }
                when (1) {
                    my $tag = set_tag_cat($place->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
                    $speak = $form . " is a lovely place, that I have not had the pleasure to visit yet.";
                    $key_colour = 2;
                }
                when (2) {
                    my $tag = set_tag_cat($place->tag, 'case', '6');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
                    $speak = $form . " is wonderful in spring. I find their Easter celebrations charming.";
                    $key_colour = 2;
                }
                when (3) {
                    my $tag = set_tag_cat($place->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
                    $speak = "Ah, " . $form . ", I have not visited for a long time, but I remember having a great vacation time.";
                    $key_colour = 4;
                }
                when (4) {
                    my $tag = set_tag_cat($place->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
                    $speak = "I am not aware of what " . $form . " has to offer to the global culture.";
                    $key_colour = 1;
                }
                when (5) {
                    my $tag = set_tag_cat($place->tag, 'case', '6');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
                    $speak = "I have a conference to attend in " . $form . " next week, and I am looking forward to visiting.";
                    $key_colour = 3;
                }
                when (6) {
                    my $tag = set_tag_cat($place->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
                    $speak = "I am planning to visit " . $form . " in order to better assess the situation and listen to the people's input.";
                    $key_colour = 4;
                }
                when (7) {
                    my $tag = set_tag_cat($place->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
                    $speak = "I would not like to interfere with the situation in " . $form . " as we do not have a good understanding of the events.";
                    $key_colour = 4;
                }
                when (8) {
                    my $tag = set_tag_cat($place->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
                    $speak = "I would not like to interfere with the situation in " . $form . " as we do not have a good understanding of the events.";
                    $key_colour = 4;
                }
                when (9) {
                    my $tag = set_tag_cat($place->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
                    $speak = $form . " is a great place to visit, with an interesting culture and centuries-long history.";
                    $key_colour = 4;
                }
                when (10) {
                    my $tag = set_tag_cat($place->tag, 'case', '1');
                    my $form = ucfirst $generator->get_form($place->lemma, $tag);
                    $speak = "I love the people of " . $form . ".";
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

sub uvod {
    my ($anodes) = @_;
    my $speak;

    if ("how" ~~ @words && "are" ~~ @words && "you" ~~ @words) { # LENGTH OF STR <4
        $speak = "I am doing great, thank you.";
        return $speak;
    }
    if ("what" ~~ @words && "your" ~~ @words && "name" ~~ @words) { # DOESN'T BELONG HERE
        $speak = "My name is Humphrey Smith.";
        return $speak;
    }
    if ("how" ~~ @words && "old" ~~ @words && "you" ~~ @words) {
        $speak = "Quite old.";
        return $speak;
    }
    if ("meaning" ~~ @words && "life" ~~ @words) {
        $speak = "42.";
        return $speak;
    }

    return $speak;
}

sub volby {
    my ($anodes) = @_;


}

# ridici mechanismus
my $logname = strftime("%Y-%m-%d_%H-%M-%S.log", localtime(time));
open $logfile, '>:utf8', $logname;

#print $client "Session initialized.\n";
&run_dialogue();

sub reply_hierarchy {
    my @ar = @_;
    my $speak = "";

    do {
    $speak = uvod(@ar);
    $keyword = "";
    if (!defined $speak || length($speak) <= 0) {
        $speak = did(@ar);
        $keyword = "";
        if (!defined $speak || length($speak) <= 0) {
            $speak = name(@ar);
            if (!defined $speak || length($speak) <= 0) {
                $speak = place(@ar);
                if (!defined $speak || length($speak) <= 0) {
                    $speak = nazor(@ar);
                    $keyword = "";
                    if (!defined $speak || length($speak) <= 0) {
                        $speak = pojem(@ar);
                        if (!defined $speak || length($speak) <= 0) {
                            $speak = general_noun(@ar);
                            $keyword = "";
                            if (!defined $speak || length($speak) <= 0) {
                                #$speak = what(@ar);
                                #if (!defined $speak || length($speak) <= 0) {
                                    $speak = nothing_to_say();
                                    $keyword = "";
                                #}
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
    say "keyword ". $keyword;
    say $keys{$keyword};
    say "key_col ". $key_colour;
    #say defined $keys{$keyword};
    } while (defined $keys{$keyword} && $keys{$keyword} != $key_colour);
    #say $keyword;
    #say $keys{$keyword};
    if (!defined $keys{$keyword} && length($keyword)>1) {
        say "save " . $keyword;
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
	    my @anodes = ($document->get_bundles())[0]->get_tree('en','a')->get_descendants({ordered => 1});
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
