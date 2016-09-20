#!/bin/bash
# set verbose mode, 
# see http://stackoverflow.com/questions/2853803/in-a-shell-script-echo-shell-commands-as-they-are-executed
#
# hugely useful, for example:
#       vim opt-args-test-cases.sh && ./opt-args-test-cases.sh && vim -p environments-second-opt-args.tex environments-second-opt-args-mod2.tex
set -x 

# optional arguments in environments
latexindent.pl environments-first-opt-args.tex -m  -tt -s -o=environments-first-opt-args-mod0.tex
latexindent.pl environments-first-opt-args-remove-linebreaks1.tex -m  -tt -s -o=environments-first-opt-args-remove-linebreaks1-mod0.tex
latexindent.pl environments-simple-opt-args.tex -m  -tt -s -o=environments-simple-opt-args-out.tex
# loop through -opt-args-mod<i>.yaml, from i=1...16
set +x
for (( i=1 ; i <= 16 ; i++ )) 
do 
   set -x
   latexindent.pl environments-first-opt-args.tex -m  -tt -s -o=environments-first-opt-args-mod$i.tex -l=opt-args-mod$i.yaml 
   latexindent.pl environments-first-opt-args.tex -m  -tt -s -o=environments-first-opt-args-mod-supp$i.tex -l=opt-args-mod$i.yaml,opt-args-supp.yaml 
   latexindent.pl environments-first-opt-args-remove-linebreaks1.tex -m  -tt -s -o=environments-first-opt-args-remove-linebreaks1-mod$i.tex -l=opt-args-mod$i.yaml 
   latexindent.pl environments-first-opt-args-remove-linebreaks1.tex -m  -tt -s -o=environments-first-opt-args-remove-linebreaks1-mod-supp$i.tex -l=opt-args-mod$i.yaml,opt-args-supp.yaml
   latexindent.pl environments-first-opt-args-remove-linebreaks2.tex -m  -tt -s -o=environments-first-opt-args-remove-linebreaks2-mod-supp$i.tex -l=opt-args-mod$i.yaml,unprotect-blank-lines.yaml
   latexindent.pl environments-second-opt-args.tex -m -l=opt-args-mod$i.yaml -tt -s -o=environments-second-opt-args-mod$i.tex 
   latexindent.pl environments-second-opt-args-remove-linebreaks1.tex -m -l=opt-args-mod$i.yaml -tt -s -o=environments-second-opt-args-remove-linebreaks1-mod$i.tex 
   latexindent.pl environments-second-opt-args-remove-linebreaks1.tex -m -l=opt-args-mod$i.yaml,unprotect-blank-lines.yaml -tt -s -o=environments-second-opt-args-remove-linebreaks1-mod-unprotect$i.tex 
   latexindent.pl environments-second-opt-args-remove-linebreaks1.tex -m -l=opt-args-mod$i.yaml,unprotect-blank-lines.yaml,condense-blank-lines.yaml -tt -s -o=environments-second-opt-args-remove-linebreaks1-mod-unprotect-condense$i.tex 
   latexindent.pl environments-third-opt-args-remove-linebreaks1-trailing-comments.tex -m -l=opt-args-mod$i.yaml -s -tt -o=environments-third-opt-args-remove-linebreaks1-trailing-comments-mod$i.tex
   latexindent.pl environments-third-opt-args.tex -m -l=opt-args-mod$i.yaml,addPercentAfterBegin.yaml -tt -s -o=environments-third-opt-args-mod$i.tex -g=other.log
   set +x
done
latexindent.pl environments-third-opt-args-remove-linebreaks1-trailing-comments.tex -m -l=opt-args-mod1.yaml,addPercentAfterBegin.yaml -s -tt -o=environments-third-opt-args-remove-linebreaks1-trailing-comments-mod1-addPercentAfterBegin.tex
latexindent.pl environments-third-opt-args.tex -l=opt-args-mod1.yaml,addPercentBeforeBegin.yaml -m -s -o=environments-third-opt-args-percent-before-begin.tex
latexindent.pl environments-third-opt-args.tex -l=addPercentAfterEnd.yaml -m -s -o=environments-third-opt-args-percent-after-end.tex
latexindent.pl environments-third-opt-args.tex -l=addPercentAfterBody.yaml -m -s -o=environments-third-opt-args-percent-after-body.tex
latexindent.pl -m -w environments-first-opt-args-mod-supp1.tex -l=addPercentAfterBody.yaml -o=environments-first-opt-args-mod-supp1-mod1.tex 
latexindent.pl environments-first-opt-args-more-comments.tex -m -l=addPercentAfterBegin.yaml  -tt -o=environments-first-opt-args-more-comments-addPercentAfterBegin.tex
   
set -x
# FIXTHIS- NEED TO RETURN TO THIS FILE
# FIXTHIS- NEED TO RETURN TO THIS FILE
# FIXTHIS- NEED TO RETURN TO THIS FILE
#latexindent.pl environments-more-opt-mand-args.tex -s
git status
exit
