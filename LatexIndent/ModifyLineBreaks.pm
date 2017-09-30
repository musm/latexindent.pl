package LatexIndent::ModifyLineBreaks;
#	This program is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	See http://www.gnu.org/licenses/.
#
#	Chris Hughes, 2017
#
#	For all communication, please visit: https://github.com/cmhughes/latexindent.pl
use strict;
use warnings;
use Data::Dumper;
use Exporter qw/import/;
use Text::Wrap;
use LatexIndent::GetYamlSettings qw/%masterSettings/;
use LatexIndent::Tokens qw/%tokens/;
use LatexIndent::TrailingComments qw/$trailingCommentRegExp/;
use LatexIndent::Switches qw/$is_m_switch_active $is_t_switch_active $is_tt_switch_active/;
use LatexIndent::Item qw/$listOfItems/;
use LatexIndent::LogFile qw/$logger/;
our @EXPORT_OK = qw/modify_line_breaks_body modify_line_breaks_end adjust_line_breaks_end_parent remove_line_breaks_begin max_char_per_line paragraphs_on_one_line construct_paragraph_reg_exp one_sentence_per_line/;
our $paragraphRegExp = q();


sub modify_line_breaks_body{
    my $self = shift;

    # add a line break after \begin{statement} if appropriate
    if(defined ${$self}{BodyStartsOnOwnLine}){
      my $BodyStringLogFile = ${$self}{aliases}{BodyStartsOnOwnLine}||"BodyStartsOnOwnLine";
      if(${$self}{BodyStartsOnOwnLine}>=1 and !${$self}{linebreaksAtEnd}{begin}){
          # if the <begin> statement doesn't finish with a line break, 
          # then we have different actions based upon the value of BodyStartsOnOwnLine:
          #     BodyStartsOnOwnLine == 1 just add a new line
          #     BodyStartsOnOwnLine == 2 add a comment, and then new line
          #     BodyStartsOnOwnLine == 3 add a blank line, and then new line
          if(${$self}{BodyStartsOnOwnLine}==1){
            # modify the begin statement
            $logger->trace("Adding a linebreak at the end of begin, ${$self}{begin} (see $BodyStringLogFile)") if $is_t_switch_active;
            ${$self}{begin} .= "\n";       
            ${$self}{linebreaksAtEnd}{begin} = 1;
            $logger->trace("Removing leading space from body of ${$self}{name} (see $BodyStringLogFile)") if $is_t_switch_active;
            ${$self}{body} =~ s/^\h*//;       
          } elsif(${$self}{BodyStartsOnOwnLine}==2){
            # by default, assume that no trailing comment token is needed
            my $trailingCommentToken = q();
            if(${$self}{body} !~ m/^\h*$trailingCommentRegExp/s){
                # modify the begin statement
                $logger->trace("Adding a % at the end of begin ${$self}{begin} followed by a linebreak ($BodyStringLogFile == 2)") if $is_t_switch_active;
                $trailingCommentToken = "%".$self->add_comment_symbol;
                ${$self}{begin} =~ s/\h*$//;       
                ${$self}{begin} .= "$trailingCommentToken\n";       
                ${$self}{linebreaksAtEnd}{begin} = 1;
                $logger->trace("Removing leading space from body of ${$self}{name} (see $BodyStringLogFile)") if $is_t_switch_active;
                ${$self}{body} =~ s/^\h*//;       
            } else {
                $logger->trace("Even though $BodyStringLogFile == 2, ${$self}{begin} already finishes with a %, so not adding another.") if $is_t_switch_active;
            }
          } elsif (${$self}{BodyStartsOnOwnLine}==3){
            my $trailingCharacterToken = q();
            $logger->trace("Adding a blank line at the end of begin ${$self}{begin} followed by a linebreak ($BodyStringLogFile == 3)") if $is_t_switch_active;
            ${$self}{begin} =~ s/\h*$//;       
            ${$self}{begin} .= (${$masterSettings{modifyLineBreaks}}{preserveBlankLines}?$tokens{blanklines}:"\n")."\n";       
            ${$self}{linebreaksAtEnd}{begin} = 1;
            $logger->trace("Removing leading space from body of ${$self}{name} (see $BodyStringLogFile)") if $is_t_switch_active;
            ${$self}{body} =~ s/^\h*//;       
          } 
       } elsif (${$self}{BodyStartsOnOwnLine}==-1 and ${$self}{linebreaksAtEnd}{begin}){
          # remove line break *after* begin, if appropriate
          $self->remove_line_breaks_begin;
       }
    }
  }

sub remove_line_breaks_begin{
    my $self = shift;
    my $BodyStringLogFile = ${$self}{aliases}{BodyStartsOnOwnLine}||"BodyStartsOnOwnLine";
    $logger->trace("Removing linebreak at the end of begin (see $BodyStringLogFile)") if $is_t_switch_active;
    ${$self}{begin} =~ s/\R*$//sx;
    ${$self}{linebreaksAtEnd}{begin} = 0;
}

sub modify_line_breaks_end{
    my $self = shift;

    # possibly modify line break *before* \end{statement}
    if(defined ${$self}{EndStartsOnOwnLine}){
          my $EndStringLogFile = ${$self}{aliases}{EndStartsOnOwnLine}||"EndStartsOnOwnLine";
          if(${$self}{EndStartsOnOwnLine}>=1 and !${$self}{linebreaksAtEnd}{body}){
              # if the <body> statement doesn't finish with a line break, 
              # then we have different actions based upon the value of EndStartsOnOwnLine:
              #     EndStartsOnOwnLine == 1 just add a new line
              #     EndStartsOnOwnLine == 2 add a comment, and then new line
              #     EndStartsOnOwnLine == 3 add a blank line, and then new line
              $logger->trace("Adding a linebreak at the end of body (see $EndStringLogFile)") if $is_t_switch_active;

              # by default, assume that no trailing character token is needed
              my $trailingCharacterToken = q();
              if(${$self}{EndStartsOnOwnLine}==2){
                $logger->trace("Adding a % immediately after body of ${$self}{name} ($EndStringLogFile==2)") if $is_t_switch_active;
                $trailingCharacterToken = "%".$self->add_comment_symbol;
                ${$self}{body} =~ s/\h*$//s;
              } elsif (${$self}{EndStartsOnOwnLine}==3) {
                $logger->trace("Adding a blank line immediately after body of ${$self}{name} ($EndStringLogFile==3)") if $is_t_switch_active;
                $trailingCharacterToken = "\n".(${$masterSettings{modifyLineBreaks}}{preserveBlankLines}?$tokens{blanklines}:q());
                ${$self}{body} =~ s/\h*$//s;
              }
              
              # modified end statement
              if(${$self}{body} =~ m/^\h*$/s and ${$self}{BodyStartsOnOwnLine} >=1 ){
                ${$self}{linebreaksAtEnd}{body} = 0;
              } else {
                ${$self}{body} .= "$trailingCharacterToken\n";
                ${$self}{linebreaksAtEnd}{body} = 1;
              }
          } elsif (${$self}{EndStartsOnOwnLine}==-1 and ${$self}{linebreaksAtEnd}{body}){
              # remove line break *after* body, if appropriate

              # check to see that body does *not* finish with blank-line-token, 
              # if so, then don't remove that final line break
              if(${$self}{body} !~ m/$tokens{blanklines}$/s){
                $logger->trace("Removing linebreak at the end of body (see $EndStringLogFile)") if $is_t_switch_active;
                ${$self}{body} =~ s/\R*$//sx;
                ${$self}{linebreaksAtEnd}{body} = 0;
              } else {
                $logger->trace("Blank line token found at end of body (${$self}{name}), see preserveBlankLines, not removing line break before ${$self}{end}") if $is_t_switch_active;
              }
          }
    }

    # possibly modify line break *after* \end{statement}
    if(defined ${$self}{EndFinishesWithLineBreak}
       and ${$self}{EndFinishesWithLineBreak}>=1 
       and !${$self}{linebreaksAtEnd}{end}){
              # if the <end> statement doesn't finish with a line break, 
              # then we have different actions based upon the value of EndFinishesWithLineBreak:
              #     EndFinishesWithLineBreak == 1 just add a new line
              #     EndFinishesWithLineBreak == 2 add a comment, and then new line
              #     EndFinishesWithLineBreak == 3 add a blank line, and then new line
              my $EndStringLogFile = ${$self}{aliases}{EndFinishesWithLineBreak}||"EndFinishesWithLineBreak";
              if(${$self}{EndFinishesWithLineBreak}==1){
                $logger->trace("Adding a linebreak at the end of ${$self}{end} ($EndStringLogFile==1)") if $is_t_switch_active;
                ${$self}{linebreaksAtEnd}{end} = 1;

                # modified end statement
                ${$self}{replacementText} .= "\n";
              } elsif(${$self}{EndFinishesWithLineBreak}==2){
                if(${$self}{endImmediatelyFollowedByComment}){
                  # no need to add a % if one already exists
                  $logger->trace("Even though $EndStringLogFile == 2, ${$self}{end} is immediately followed by a %, so not adding another; not adding line break.") if $is_t_switch_active;
                } else {
                  # otherwise, create a trailing comment, and tack it on 
                  $logger->trace("Adding a % immediately after, ${$self}{end} ($EndStringLogFile==2)") if $is_t_switch_active;
                  my $trailingCommentToken = "%".$self->add_comment_symbol;
                  ${$self}{end} =~ s/\h*$//s;
                  ${$self}{replacementText} .= "$trailingCommentToken\n";
                  ${$self}{linebreaksAtEnd}{end} = 1;
                }
              } elsif(${$self}{EndFinishesWithLineBreak}==3){
                $logger->trace("Adding a blank line at the end of ${$self}{end} ($EndStringLogFile==3)") if $is_t_switch_active;
                ${$self}{linebreaksAtEnd}{end} = 1;

                # modified end statement
                ${$self}{replacementText} .= (${$masterSettings{modifyLineBreaks}}{preserveBlankLines}?$tokens{blanklines}:"\n")."\n";
              } 
    }

}

sub adjust_line_breaks_end_parent{
    # when a parent object contains a child object, the line break
    # at the end of the parent object can become messy
    return unless $is_m_switch_active;

    my $self = shift;

    # most recent child object
    my $child = @{${$self}{children}}[-1];

    # adjust parent linebreaks information
    if(${$child}{linebreaksAtEnd}{end} and ${$self}{body} =~ m/${$child}{replacementText}\h*\R*$/s and !${$self}{linebreaksAtEnd}{body}){
        $logger->trace("ID: ${$child}{id}") if($is_t_switch_active);
        $logger->trace("${$child}{begin}...${$child}{end} is found at the END of body of parent, ${$self}{name}, avoiding a double line break:") if($is_t_switch_active);
        $logger->trace("adjusting ${$self}{name} linebreaksAtEnd{body} to be 1") if($is_t_switch_active);
        ${$self}{linebreaksAtEnd}{body}=1;
      }

    # the modify line switch can adjust line breaks, so we need another check, 
    # see for example, test-cases/environments/environments-remove-line-breaks-trailing-comments.tex
    if(defined ${$child}{linebreaksAtEnd}{body} 
        and !${$child}{linebreaksAtEnd}{body} 
        and ${$child}{body} =~ m/\R(?:$trailingCommentRegExp\h*)?$/s ){
        # log file information
        $logger->trace("Undisclosed line break at the end of body of ${$child}{name}: '${$child}{end}'") if($is_t_switch_active);
        $logger->trace("Adding a linebreak at the end of body for ${$child}{id}") if($is_t_switch_active);
        
        # make the adjustments
        ${$child}{body} .= "\n";
        ${$child}{linebreaksAtEnd}{body}=1;
    }

}

sub max_char_per_line{
    return unless $is_m_switch_active;

    my $self = shift;
    return unless ${$masterSettings{modifyLineBreaks}{textWrapOptions}}{columns}>1;

    # call the text wrapping routine
    $Text::Wrap::columns=${$masterSettings{modifyLineBreaks}{textWrapOptions}}{columns};
    if(${$masterSettings{modifyLineBreaks}{textWrapOptions}}{separator} ne ''){
        $Text::Wrap::separator=${$masterSettings{modifyLineBreaks}{textWrapOptions}}{separator};
    }
    ${$self}{body} = wrap('','',${$self}{body});
}

sub construct_paragraph_reg_exp{
    my $self = shift;

    $logger->trace("*Constructing the paragraph-stop regexp (see paragraphsStopAt)") if $is_t_switch_active ;
    my $stopAtRegExp = q();
    while( my ($paragraphStopAt,$yesNo)= each %{${$masterSettings{modifyLineBreaks}{removeParagraphLineBreaks}}{paragraphsStopAt}}){
        if($yesNo){
            # the headings (chapter, section, etc) need a slightly special treatment
            $paragraphStopAt = "afterHeading" if($paragraphStopAt eq "heading");

            # the comment need a slightly special treatment
            $paragraphStopAt = "trailingComment" if($paragraphStopAt eq "comments");

            # output to log file
            $logger->trace("The paragraph-stop regexp WILL include $tokens{$paragraphStopAt} (see paragraphsStopAt)") if $is_t_switch_active ;

            # update the regexp
            if($paragraphStopAt eq "items"){
                $stopAtRegExp .= "|(?:\\\\(?:".$listOfItems."))";
            } else {
                $stopAtRegExp .= "|(?:".($paragraphStopAt eq "trailingComment" ? "%" : q() ).$tokens{$paragraphStopAt}."\\d+)";
            }
        } else {
            $logger->trace("The paragraph-stop regexp won't include $tokens{$paragraphStopAt} (see paragraphsStopAt)") if ($tokens{$paragraphStopAt} and $is_t_switch_active);
        }
    }

    $paragraphRegExp = qr/
                        ^
                        (?!$tokens{beginOfToken})
                        (\w
                            (?:
                                (?!
                                    (?:$tokens{blanklines}|\\par) 
                                ).
                            )*?
                         )
                         (
                            (?:
                                ^(?:(\h*\R)|\\par|$tokens{blanklines}$stopAtRegExp)
                            )
                            |
                            \z      # end of string
                         )/sxm;

    $logger->trace("The paragraph-stop-regexp is:") if $is_tt_switch_active ;
    $logger->trace($paragraphRegExp) if $is_tt_switch_active ;
}

sub paragraphs_on_one_line{
    my $self = shift;
    return unless ${$self}{removeParagraphLineBreaks};

    # alignment at ampersand can take priority
    return if(${$self}{lookForAlignDelims} and ${$masterSettings{modifyLineBreaks}{removeParagraphLineBreaks}}{alignAtAmpersandTakesPriority});

    $logger->trace("Checking ${$self}{name} for paragraphs (see removeParagraphLineBreaks)") if $is_t_switch_active;

    my $paragraphCounter;
    my @paragraphStorage;

    ${$self}{body} =~ s/$paragraphRegExp/
                            $paragraphCounter++;
                            push(@paragraphStorage,{id=>$tokens{paragraph}.$paragraphCounter.$tokens{endOfToken},value=>$1});

                            # replace comment with dummy text
                            $tokens{paragraph}.$paragraphCounter.$tokens{endOfToken}.$2;
                        /xsmeg;

    while( my $paragraph = pop @paragraphStorage){
      # remove all line breaks from paragraph, except for any at the very end
      ${$paragraph}{value} =~ s/\R(?!\z)/ /sg; 
      ${$self}{body} =~ s/${$paragraph}{id}/${$paragraph}{value}/; 
    }
}

sub one_sentence_per_line{
    my $self = shift;

    return unless ${$masterSettings{modifyLineBreaks}{oneSentencePerLine}}{manipulateSentences};
    $logger->trace("*One sentence per line regular expression construction: (see oneSentencePerLine)") if $is_t_switch_active;

    my $sentencesFollow = qr/(?:\A(?!(?:\R*$tokens{blanklines})))|(?:\G(?!(?:\R*$tokens{blanklines})))/s;

    while( my ($sentencesFollowEachPart,$yesNo)= each %{${$masterSettings{modifyLineBreaks}{oneSentencePerLine}}{sentencesFollow}}){
        if($yesNo){
            if($sentencesFollowEachPart eq "par"){
                $sentencesFollowEachPart = qr/\\par/s;
            } elsif ($sentencesFollowEachPart eq "blankLine"){
                $sentencesFollowEachPart = qr/(?:(?:\R$tokens{blanklines}\R)|\R{2,})/s;
            } elsif ($sentencesFollowEachPart eq "fullStop"){
                $sentencesFollowEachPart = qr/\./s;
            } elsif ($sentencesFollowEachPart eq "rightBracket"){
                $sentencesFollowEachPart = qr/\)/s;
            }
            $sentencesFollow .= "|".$sentencesFollowEachPart;
        }
    }
    $sentencesFollow = qr/$sentencesFollow/s;

    $sentencesFollow = qr/(?:\A$tokens{blanklines}\R)
                                |
                        (?:\G$tokens{blanklines}\R)
                                |
                        (?:$tokens{blanklines}\h*\R)
                                |
                                \R{2,}
                                |
                                \G
                                |
                                \.
                                |
                                \)
                                |
                                \?
                                |
                                !
                        /sx;

    $logger->trace("Sentences follow regexp:") if $is_tt_switch_active;
    $logger->trace($sentencesFollow) if $is_tt_switch_active;

    my $sentencesEndWith = q();

    while( my ($sentencesEndWithEachPart,$yesNo)= each %{${$masterSettings{modifyLineBreaks}{oneSentencePerLine}}{sentencesEndWith}}){
        if($yesNo){
            if($sentencesEndWithEachPart eq "fullStop"){
                $sentencesEndWithEachPart = qr/\./;
            } elsif ($sentencesEndWithEachPart eq "exclamationMark"){
                $sentencesEndWithEachPart = qr/!/;
            } elsif ($sentencesEndWithEachPart eq "questionMark"){
                $sentencesEndWithEachPart = qr/\?/;
            }
            $sentencesEndWith .= ($sentencesEndWith eq "" ? q(): "|" ).$sentencesEndWithEachPart;
        }
    }
    $sentencesEndWith = qr/$sentencesEndWith/;

    $logger->trace("Sentences end with regexp:") if $is_tt_switch_active;
    $logger->trace($sentencesEndWith) if $is_tt_switch_active;

    $logger->trace("Finding sentences") if $is_t_switch_active;

    ${$self}{body} =~ s/($sentencesFollow)
                            \h*
                            (?!$trailingCommentRegExp)
                            (.*?)
                            ($sentencesEndWith)
                            \h*
                            \R?/
                            my $beginning = $1;
                            my $middle    = $2;
                            my $end       = $3;
                            # remove line breaks from within a sentence
                            $middle =~ s|
                                            (?!\A)      # not at the *beginning* of a match
                                            (\h*)\R     # possible horizontal space, then line break
                                        |$1?$1:" ";|esgx;
                            # reconstruct the sentence
                            $beginning.$middle.$end."\n";
                            /xsge;
}

1;
