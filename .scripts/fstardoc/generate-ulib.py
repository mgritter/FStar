import fstardoc
import glob
import os.path
import os
import gh_md_to_html
import requests
import base64

# TODO: take these as command-line argumnets
fstar_base='/home/mark/FStar'
ulib_base=os.path.join( fstar_base, 'ulib' )
md_base='/home/mark/fstarmd'
gh_pages_base='/home/mark/fstarlang.github.io'
docs_base=os.path.join( gh_pages_base, 'docs' )

interface_sources = glob.glob( os.path.join( ulib_base, 'FStar.*.fsti' ))
impl_sources = glob.glob( os.path.join( ulib_base, 'FStar.*.fst' ))

def change_suffix( fn, suffix ):
    components = fn.split( "." )
    components[-1] = suffix
    return ".".join( components )

def baseName( fn ):
    components = fn.split( "." )
    return ".".join( components[:-1] )
    
sources = set( os.path.basename( s ) for s in interface_sources )
sources.update( os.path.basename( s ) for s in impl_sources
                if change_suffix( os.path.basename(s), "fsti" ) not in sources )

errors = set()

print( f"Generating documentation for {len(sources)} files." )

introductions = {}

def infer_introduction( module, md ):
    # Split back into lines -- FIXME
    lines = md.split("\n" )
    try:
        headerLoc = lines.index( f"# {module}" )
    except ValueError:
        return

    # Find the introductory section prefixed with '> '
    # after the module definition (possibly after a copyright notice.)
    
    firstParagraph = ""
    for l in lines[headerLoc + 1:]:
        # skip blank lines
        if l == "":
            continue
        
        # skip blank lines, if no paragraph, otherwise end
        if l.rstrip() == ">":
            if firstParagraph == "":
                continue
            else:
                break
            
        if l.startswith( "> " ):
            firstParagraph += " "
            firstParagraph += l[2:] 
            continue

        # unknown start of line, skip
        break
    
    if firstParagraph == "":
        # Look for @summary tag--- this isn't currently translated by
        # fstardoc, but some still have them.
        try:
            i1 = md.index( "@summary ")
            i2 = md.index( "\n\n", i1 )
            firstParagraph = md[i1 + len( "@summary" ) : i2 ]
        except ValueError:
            return

    try:
        firstPeriod = firstParagraph.index( ". " )
        # hack, replace the search with a regexp
        while firstParagraph[firstPeriod-3:firstPeriod+1] == "i.e.":
            firstPeriod = firstParagraph.index( ". ", firstPeriod + 1 )
        firstSentence = firstParagraph[:firstPeriod+1]
    except ValueError:
        firstSentence = firstParagraph

    introductions[module] = firstSentence
    
for s in sources:
    try:
        with open( os.path.join( ulib_base, s ), "r" ) as fstar_in:        
            with open( os.path.join( md_base, change_suffix( s, "md" ) ), "w" ) as md_out:
                fst = fstar_in.read()
                md = fstardoc.fst2md( fst )
                md_out.write( md )
                infer_introduction( baseName( s ), md ) 
    except AssertionError as e:
        firstLine = e.args[0].split( '\n' )[0]
        secondLine = e.args[0].split( '\n' )[1]
        print( f"Error in {s}: {firstLine}" )
        print( secondLine )
        errors.add( s )

sources.difference_update( errors )

with open( os.path.join( md_base, "index.md" ), "w" ) as index_out:
    index_out.write( "# F* standard library modules\n\n" )
    for s in sorted( sources, key=baseName ):
        n = baseName( s )
        try:
            intro = introductions[n]
            index_out.write( f"[{n}]({n}.html) -- {intro}\n\n" )
        except KeyError:
            index_out.write( f"[{n}]({n}.html)\n\n" )
            

sources.add( "index.md" )

# The Github API doesn't provide HTML headers, so use some canned ones
# (and set the title while we're at it.)
# The divs are copied from gh_md_to_html
template = """<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>{title}</title>
  <link rel="stylesheet" href="gh-style.css"/>
</head>
<body>
<div class="gist">
    <style class="formula-style">
        svg.gh-md-to-html-formula {{
            fill: black;
        }}
    </style>
    <div class="gist-file">
        <div class="gist-data">
            <div class="js-gist-file-update-container js-task-list-container file-box">
                <div class="file">
                    <div id="file-docker-image-pull-md-readme" class="Box-body readme blob js-code-block-container p-5 p-xl-6"
                         style="margin-left: 40px; margin-right: 40px; margin-top: 20px; margin-bottom: 20px">
                        <article class="markdown-body entry-content container-lg" itemprop="text">
                            {body}
                        </article>
                    </div>
                </div>
            </div>
        </div>
     </div>
 </div>
</body>
</html>
"""


def markdown_to_html_via_github_api(markdown, title):
    """Converts markdown to html, using the github api and nothing else."""
    headers = {"Content-Type": "text/plain", "charset": "utf-8",
               "accept": "application/vnd.github.v3+json"}
    
    auth = None
    pat = os.getenv( "GITHUB_PERSONAL_ACCESS_TOKEN" )
    if pat != "":
        user = os.getenv( "GITHUB_USER" )
        auth = requests.auth.HTTPBasicAuth( user, pat )

    req = {
        'text' : markdown,
        'mode' : "markdown",
    }
                     
    resp = requests.post("https://api.github.com/markdown",
                         headers=headers,
                         json=req,
                         auth=auth)
    if resp.headers["x-ratelimit-remaining"] == "0":
        raise Exception("Rate limit cap hit, trying using GITHUB_PERSONAL_ACCESS_TOKEN.")
    
    return template.format(
        body = str(resp.content, encoding="utf-8"),
        title = title
        )

for s in sources:
    src = os.path.join( md_base, change_suffix( s, "md" ) )
    dst = os.path.join( docs_base, change_suffix( s, "html" ) )
    print( f"Converting {src}")
    title = baseName( s )
    with open( src, "r" ) as md_in:
        with open( dst, "w" ) as html_out:
            html_out.write( markdown_to_html_via_github_api(md_in.read(), title) )
