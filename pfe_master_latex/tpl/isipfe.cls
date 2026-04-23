%========= ISIPFE LaTeX Class — adapted for ESPRIT =========%
% Based on the ISI PFE template by HEDHILI Med Houssemeddine
% Adapted for ESPRIT / Sopra Steria — 2026
%==========================================================%

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{isipfe}[2026/04/18 ESPRIT PFE LaTeX Class]

% ifthenelse for if loops
\RequirePackage{ifthen}

% if two candidates
\newboolean{isBinomal}
\setboolean{isBinomal}{false}
\DeclareOption{isBinomal}{\setboolean{isBinomal}{true}}

\newboolean{wantToTypeCompanyAddress}
\setboolean{wantToTypeCompanyAddress}{false}
\DeclareOption{wantToTypeCompanyAddress}{\setboolean{wantToTypeCompanyAddress}{true}}

% finished processing options
\ProcessOptions\relax

% load the book class using a4paper
\LoadClass[12pt,a4paper,oneside]{book}
\usepackage[a4paper]{geometry}

%% lmodern: full T1 font support (fixes missing œ, è, etc.)
\usepackage{lmodern}

% give the header a bit more room for fancyhdr (must be >= 15pt)
\setlength{\headheight}{15pt}

% first set to zero ...
\setlength{\oddsidemargin}{-1in}
\setlength{\evensidemargin}{-1in}
\setlength{\topmargin}{-1in}

% adjust these if printer is off by a bit
\setlength{\hoffset}{0mm}
\setlength{\voffset}{0mm}

\addtolength{\oddsidemargin}{22mm}
\addtolength{\evensidemargin}{22mm}
\addtolength{\topmargin}{20mm}

% set up some of the spacing
\setlength{\marginparwidth}{40pt}
\setlength{\marginparsep}{10pt}
\setlength{\headsep}{0.2in}

% A4 dimensions [mm]: 209.903 x 297.039
\setlength{\textwidth}{21cm}
\setlength{\textheight}{30cm}

% fix up width
\addtolength{\textwidth}{-\oddsidemargin}
\addtolength{\textwidth}{-\evensidemargin}
\addtolength{\textwidth}{-2in}

% fix up height
\addtolength{\textheight}{-2\topmargin}
\addtolength{\textheight}{-\headheight}
\addtolength{\textheight}{-\headsep}
\addtolength{\textheight}{-\footskip}
\addtolength{\textheight}{-2in}

\brokenpenalty=10000

% this stops one figure taking up a whole page
\renewcommand\floatpagefraction{0.8}

%% microtype for better spacing
\usepackage{microtype}

%% Defining section, subsection and subsubsection spacing AND format
\usepackage{titlesec}
\titlespacing*{\section}{7mm}{12pt}{8pt}
\titlespacing*{\subsection}{15mm}{12pt}{8pt}
\titlespacing*{\subsubsection}{18mm}{12pt}{6pt}

% Fix stretched spaces in section/subsection titles
\titleformat{\section}{\large\bfseries\raggedright}{\thesection}{1em}{}
\titleformat{\subsection}{\normalsize\bfseries\raggedright}{\thesubsection}{1em}{}
\titleformat{\subsubsection}{\normalsize\bfseries\raggedright}{\thesubsubsection}{1em}{}

% use 1.5 line spacing
\usepackage{setspace}
\setstretch{1.6}

\setlength{\parindent}{12mm}

%%% load the required packages
\RequirePackage{fancyhdr}
\RequirePackage{xspace}

%================ Languages ================%
\usepackage{iftex}
\ifPDFTeX
\usepackage[utf8]{inputenc}
\fi
\usepackage[T1]{fontenc}
\usepackage[french,english]{babel}

\frenchbsetup{LowercaseSuperscripts=false}
\usepackage{csquotes}
%% Use bibtex backend consistently (avoids fall-back warning)
\usepackage[backend=bibtex,style=ieee,sorting=none]{biblatex}
\addbibresource{Biblio.bib}

%============== List Customization ==============%
\usepackage{enumitem}
\usepackage{datatool}
\newcommand{\sortitem}[2][\relax]{%
    \DTLnewrow{list}%
    \DTLnewdbentry{list}{sortlabel}{#1}
    \DTLnewdbentry{list}{description}{
        \begin{minipage}[l]{0.1\columnwidth}
        ~\textbf{#1}
        \end{minipage}
        \begin{minipage}[l]{0.05\columnwidth}
        \textbf{=}
        \end{minipage}
        \begin{minipage}[l]{0.85\columnwidth}
        #2
        \end{minipage}
    }%
}
\newenvironment{acronyms}{%
    \DTLifdbexists{list}{\DTLcleardb{list}}{\DTLnewdb{list}}%
}{%
    \DTLsort{sortlabel}{list}%
    \begin{itemize}%
    \DTLforeach*{list}{\theDesc=description}{%
        \item \theDesc}%
    \end{itemize}%
}

%================= Custom Colors =================%
\usepackage[table]{xcolor}
\definecolor{isiBlue}{RGB}{31, 78, 121}

%================= minitoc ==================%
\usepackage[french]{minitoc}
\mtcsettitle{minitoc}{Sommaire}
\setcounter{minitocdepth}{1}
\mtcsetrules{minitoc}{off}
\mtcsetoffset{minitoc}{-1.0em}

%% disabling chapter numbers in minitoc
\newcommand{\filterminitoc}[1]{#1}
\renewcommand{\thesection}{\csname filterminitoc \endcsname{\arabic{chapter}.}\arabic{section}}
\newcommand{\minitocsection}{\begingroup\renewcommand{\filterminitoc}[1]{}\minitoc\endgroup}

%=============== Customizing Chapters Names ===============%
\usepackage{pstricks}
\makeatletter
\def\thickhrulefill{\leavevmode \leaders \hrule height 1.2ex \hfill \kern \z@}

\def\@makechapterhead#1{
    \vspace*{30\p@}%
    {\parindent \z@ \centering \reset@font
    \thickhrulefill\quad
    \scshape\bfseries\@chapapp{}  \thechapter
    \quad \thickhrulefill
    \par\nobreak
    \vspace*{10\p@}%
    \interlinepenalty\@M
    \hrule
    \vspace*{10\p@}%
    \Huge \bfseries #1 \par\nobreak
    \par
    \vspace*{10\p@}%
    \hrule
    \vskip 50\p@
    }
    \minitocsection
    \thispagestyle{empty}%
    \newpage
}
\def\@makeschapterhead#1{\hbox{%
    \huge\hbox{\textbf{#1}}%
}\par\vskip 1cm}

%============== Table & Figure Captions ==============%

\usepackage{caption}
\captionsetup[table]{
    labelfont=bf,
    labelsep = newline,
    name = Tableau,
    justification=justified,
    singlelinecheck=false,
    labelsep=colon,
    skip = \medskipamount}

\captionsetup[figure]{
    labelfont=bf,
    labelsep = newline,
    name = Figure,
    justification=centering,
    singlelinecheck=false,
    labelsep=colon,
    skip = \medskipamount}

%%%%% Fancyhdr stuff
\fancyhf{}
\renewcommand{\headrulewidth}{0.3pt}
\renewcommand{\footrulewidth}{0.3pt}
\pagestyle{fancy}
\lhead{\nouppercase{\leftmark}}
\rfoot{\centering \thepage}

%=============== Fancy Page Styles ===============%

\fancypagestyle{frontmatter}{%
    \fancyhf{}%
    \renewcommand{\footrulewidth}{0.3pt}%
    \renewcommand{\headrulewidth}{0pt}%
    \fancyfoot[r]{\footnotesize \thepage}%
}

\fancypagestyle{lscape}{
    \fancyhf{}
    \renewcommand{\footrulewidth}{0pt}
    \renewcommand{\headrulewidth}{0pt}
}

\fancypagestyle{plain}{
    \fancyhf{}
    \renewcommand{\footrulewidth}{0.3pt}
    \renewcommand{\headrulewidth}{0pt}
    \fancyfoot[c]{\footnotesize \thepage}
}

\fancypagestyle{cover}{
    \fancyhf{}
    \renewcommand{\footrulewidth}{0pt}
    \renewcommand{\headrulewidth}{0pt}
    \fancyfoot[C]{{\noindent\makebox[\textwidth][c]{Année Universitaire \@collegeYear}}}
}

\fancypagestyle{backcover}{
    \fancyhf{}
    \renewcommand{\footrulewidth}{0pt}
    \renewcommand{\headrulewidth}{0pt}
    \setlength{\headheight}{0mm}
}

% standard graphics packages
\usepackage{graphicx}
\usepackage{graphics}
\usepackage{float}

%% Extra packages for code listings, math, etc.
\usepackage{listings}
\usepackage{fancyvrb}
\usepackage{booktabs}
\usepackage{longtable}
\usepackage{tabularx}
\usepackage{arydshln}
\usepackage{array}
\usepackage{multirow}
\usepackage{colortbl}
\usepackage{subcaption}
\usepackage{makeidx}
\usepackage{emptypage}
\usepackage{mdframed}
\usepackage{amsthm}
\usepackage[nottoc]{tocbibind}
\usepackage[hidelinks]{hyperref}
\usepackage{bookmark}
\usepackage{lastpage}

%% Code listings style
\definecolor{codebg}{RGB}{248,248,248}
\definecolor{codeframe}{RGB}{200,200,200}
\definecolor{keyword}{RGB}{0,0,180}
\definecolor{comment}{RGB}{60,130,60}
\definecolor{string}{RGB}{160,0,0}

\lstset{
    backgroundcolor=\color{codebg},
    frame=single,
    rulecolor=\color{codeframe},
    basicstyle=\footnotesize\ttfamily,
    keywordstyle=\color{keyword}\bfseries,
    commentstyle=\color{comment}\itshape,
    stringstyle=\color{string},
    breaklines=true,
    breakatwhitespace=true,
    numbers=left,
    numberstyle=\tiny\color{gray},
    numbersep=8pt,
    xleftmargin=12pt,
    captionpos=b,
    showstringspaces=false
}

%% Theorems and boxes
\newtheorem{theorem}{Théorème}[chapter]
\newtheorem{definition}{Définition}[chapter]
\newtheorem{exemple}{Exemple}[chapter]

\providecommand{\keywords}[1]{\textbf{\textit{Mots-clés~:}} #1}
\providecommand{\keywordss}[1]{\textbf{\textit{Keywords~:}} #1}

%% Warning box
\newmdenv[
    backgroundcolor=yellow!8,
    linecolor=orange!80,
    linewidth=2pt,
    leftline=true, rightline=false, topline=false, bottomline=false,
    innerleftmargin=10pt, innerrightmargin=8pt,
    innertopmargin=5pt, innerbottommargin=5pt
]{warningbox}

%% Info box
\newmdenv[
    backgroundcolor=isiBlue!5,
    linecolor=isiBlue,
    linewidth=2pt,
    leftline=true, rightline=false, topline=false, bottomline=false,
    innerleftmargin=10pt, innerrightmargin=8pt,
    innertopmargin=5pt, innerbottommargin=5pt
]{infobox}

%% Extra packages
\usepackage{tcolorbox}
\usepackage{afterpage}
\usepackage{pifont}
\usepackage{pdflscape}
\usepackage{rotating}
\usepackage{wrapfig}

%================ document main language ================%
\selectlanguage{french}

