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

sources = set( os.path.basename( s ) for s in interface_sources )
sources.update( os.path.basename( s ) for s in impl_sources
                if change_suffix( os.path.basename(s), "fsti" ) not in sources )

errors = set()

print( f"Generating documentation for {len(sources)} files." )

for s in sources:
    try:
        with open( os.path.join( ulib_base, s ), "r" ) as fstar_in:        
            with open( os.path.join( md_base, change_suffix( s, "md" ) ), "w" ) as md_out:
                fst = fstar_in.read()
                md_out.write( fstardoc.fst2md( fst ) )
    except AssertionError as e:
        firstLine = e.args[0].split( '\n' )[0]
        secondLine = e.args[0].split( '\n' )[1]
        print( f"Error in {s}: {firstLine}" )
        print( secondLine )
        errors.add( s )

sources.difference_update( errors )

# This is a replacement for gh_md_to_html's version, which uses an Authentication header
# so it's not rate-limited
def markdown_to_html_via_github_api(markdown):
    """Converts markdown to html, using the github api and nothing else."""
    headers = {"Content-Type": "text/plain", "charset": "utf-8"}
    auth = None
    pat = os.getenv( "GITHUB_PERSONAL_ACCESS_TOKEN" )
    if pat != "":
        user = os.getenv( "GITHUB_USER" )
        auth = requests.auth.HTTPBasicAuth( user, pat )

    resp = requests.post("https://api.github.com/markdown/raw",
                         headers=headers,
                         data=markdown.encode("utf-8"),
                         auth=auth)
    if resp.headers["x-ratelimit-remaining"] == "0":
        raise Exception("Rate limit cap hit, trying using GITHUB_PERSONAL_ACCESS_TOKEN.")
    return str(resp.content, encoding="utf-8")

for s in sources:
    src = os.path.join( md_base, change_suffix( s, "md" ) )
    
    gh_md_to_html.main(md_origin=src,
                       website_root=gh_pages_base,
                       destination="docs",
                       css_paths = "",  # inline
                       core_converter = markdown_to_html_via_github_api
                       )

    
