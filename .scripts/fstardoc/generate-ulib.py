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
    index_out.write( "# F* standard library modules" )
    for s in sorted( sources, key=baseName ):
        n = baseName( s )
        try:
            intro = introductions[n]
            index_out.write( f"[{n}]({n}.html) -- {intro}\n\n" )
        except KeyError:
            index_out.write( f"[{n}]({n}.html)\n\n" )
            

sources.add( "index.md" )

# The Github API doesn't provide HTML headers, so use some canned ones (and set the
# title while we're at it.)
template = """<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>{title}</title>
  <style>{style}</style>
</head>
<body>
{body}
</body>
</html>
"""

# Too lazy to read from a file, here's the minimized version.
gh_css_style="""@charset "utf-8"; .gist{font-size:16px;color:#333;text-align:left;/*!* GitHub Light v0.4.1 * Copyright(c) 2012 - 2017 GitHub,Inc. * Licensed under MIT(https://github.com/primer/github-syntax-theme-generator/blob/master/LICENSE) */ direction:ltr}.gist .markdown-body{font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Helvetica,Arial,sans-serif,Apple Color Emoji,Segoe UI Emoji;font-size:16px;line-height:1.5;word-wrap:break-word}.gist .markdown-body kbd{display:inline-block;padding:3px 5px;font:11px SFMono-Regular,Consolas,Liberation Mono,Menlo,monospace;line-height:10px;color:#444d56;vertical-align:middle;background-color:#fafbfc;border:1px solid #d1d5da;border-radius:3px;box-shadow:inset 0 -1px 0 #d1d5da}.gist .markdown-body:before{display:table;content:""}.gist .markdown-body:after{display:table;clear:both;content:""}.gist .markdown-body>:first-child{margin-top:0 !important}.gist .markdown-body>:last-child{margin-bottom:0 !important}.gist .markdown-body a:not([href]){color:inherit;text-decoration:none}.gist .markdown-body .absent{color:#cb2431}.gist .markdown-body .anchor{float:left;padding-right:4px;margin-left:-20px;line-height:1}.gist .markdown-body .anchor:focus{outline:none}.gist .markdown-body blockquote,.gist .markdown-body details,.gist .markdown-body dl,.gist .markdown-body ol,.gist .markdown-body p,.gist .markdown-body pre,.gist .markdown-body table,.gist .markdown-body ul{margin-top:0;margin-bottom:16px}.gist .markdown-body hr{height:.25em;padding:0;margin:24px 0;background-color:#e1e4e8;border:0}.gist .markdown-body blockquote{padding:0 1em;color:#6a737d;border-left:.25em solid #dfe2e5}.gist .markdown-body blockquote>:first-child{margin-top:0}.gist .markdown-body blockquote>:last-child{margin-bottom:0}.gist .markdown-body h1,.gist .markdown-body h2,.gist .markdown-body h3,.gist .markdown-body h4,.gist .markdown-body h5,.gist .markdown-body h6{margin-top:24px;margin-bottom:16px;font-weight:600;line-height:1.25}.gist .markdown-body h1 .octicon-link,.gist .markdown-body h2 .octicon-link,.gist .markdown-body h3 .octicon-link,.gist .markdown-body h4 .octicon-link,.gist .markdown-body h5 .octicon-link,.gist .markdown-body h6 .octicon-link{color:#1b1f23;vertical-align:middle;visibility:hidden}.gist .markdown-body h1:hover .anchor,.gist .markdown-body h2:hover .anchor,.gist .markdown-body h3:hover .anchor,.gist .markdown-body h4:hover .anchor,.gist .markdown-body h5:hover .anchor,.gist .markdown-body h6:hover .anchor{text-decoration:none}.gist .markdown-body h1:hover .anchor .octicon-link,.gist .markdown-body h2:hover .anchor .octicon-link,.gist .markdown-body h3:hover .anchor .octicon-link,.gist .markdown-body h4:hover .anchor .octicon-link,.gist .markdown-body h5:hover .anchor .octicon-link,.gist .markdown-body h6:hover .anchor .octicon-link{visibility:visible}.gist .markdown-body h1 code,.gist .markdown-body h1 tt,.gist .markdown-body h2 code,.gist .markdown-body h2 tt,.gist .markdown-body h3 code,.gist .markdown-body h3 tt,.gist .markdown-body h4 code,.gist .markdown-body h4 tt,.gist .markdown-body h5 code,.gist .markdown-body h5 tt,.gist .markdown-body h6 code,.gist .markdown-body h6 tt{font-size:inherit}.gist .markdown-body h1{font-size:2em}.gist .markdown-body h1,.gist .markdown-body h2{padding-bottom:.3em;border-bottom:1px solid #eaecef}.gist .markdown-body h2{font-size:1.5em}.gist .markdown-body h3{font-size:1.25em}.gist .markdown-body h4{font-size:1em}.gist .markdown-body h5{font-size:.875em}.gist .markdown-body h6{font-size:.85em;color:#6a737d}.gist .markdown-body ol,.gist .markdown-body ul{padding-left:2em}.gist .markdown-body ol.no-list,.gist .markdown-body ul.no-list{padding:0;list-style-type:none}.gist .markdown-body ol ol,.gist .markdown-body ol ul,.gist .markdown-body ul ol,.gist .markdown-body ul ul{margin-top:0;margin-bottom:0}.gist .markdown-body li{word-wrap:break-all}.gist .markdown-body li>p{margin-top:16px}.gist .markdown-body li+li{margin-top:.25em}.gist .markdown-body dl{padding:0}.gist .markdown-body dl dt{padding:0;margin-top:16px;font-size:1em;font-style:italic;font-weight:600}.gist .markdown-body dl dd{padding:0 16px;margin-bottom:16px}.gist .markdown-body table{display:block;width:100%;overflow:auto}.gist .markdown-body table th{font-weight:600}.gist .markdown-body table td,.gist .markdown-body table th{padding:6px 13px;border:1px solid #dfe2e5}.gist .markdown-body table tr{background-color:#fff;border-top:1px solid #c6cbd1}.gist .markdown-body table tr:nth-child(2n){background-color:#f6f8fa}.gist .markdown-body table img{background-color:initial}.gist .markdown-body img{max-width:100%;box-sizing:initial;background-color:#fff}.gist .markdown-body img[align=right]{padding-left:20px}.gist .markdown-body img[align=left]{padding-right:20px}.gist .markdown-body .emoji{max-width:none;vertical-align:text-top;background-color:initial}.gist .markdown-body span.frame{display:block;overflow:hidden}.gist .markdown-body span.frame>span{display:block;float:left;width:auto;padding:7px;margin:13px 0 0;overflow:hidden;border:1px solid #dfe2e5}.gist .markdown-body span.frame span img{display:block;float:left}.gist .markdown-body span.frame span span{display:block;padding:5px 0 0;clear:both;color:#24292e}.gist .markdown-body span.align-center{display:block;overflow:hidden;clear:both}.gist .markdown-body span.align-center>span{display:block;margin:13px auto 0;overflow:hidden;text-align:center}.gist .markdown-body span.align-center span img{margin:0 auto;text-align:center}.gist .markdown-body span.align-right{display:block;overflow:hidden;clear:both}.gist .markdown-body span.align-right>span{display:block;margin:13px 0 0;overflow:hidden;text-align:right}.gist .markdown-body span.align-right span img{margin:0;text-align:right}.gist .markdown-body span.float-left{display:block;float:left;margin-right:13px;overflow:hidden}.gist .markdown-body span.float-left span{margin:13px 0 0}.gist .markdown-body span.float-right{display:block;float:right;margin-left:13px;overflow:hidden}.gist .markdown-body span.float-right>span{display:block;margin:13px auto 0;overflow:hidden;text-align:right}.gist .markdown-body code,.gist .markdown-body tt{padding:.2em .4em;margin:0;font-size:85%;background-color:#f6f8fa;border-radius:3px}.gist .markdown-body code br,.gist .markdown-body tt br{display:none}.gist .markdown-body del code{text-decoration:inherit}.gist .markdown-body pre{word-wrap:normal}.gist .markdown-body pre>code{padding:0;margin:0;font-size:100%;word-break:normal;white-space:pre;background:transparent;border:0}.gist .markdown-body .highlight{margin-bottom:16px}.gist .markdown-body .highlight pre{margin-bottom:0;word-break:normal}.gist .markdown-body .highlight pre,.gist .markdown-body pre{padding:16px;overflow:auto;font-size:85%;line-height:1.45;background-color:#f6f8fa;border-radius:3px}.gist .markdown-body pre code,.gist .markdown-body pre tt{display:inline;max-width:auto;padding:0;margin:0;overflow:visible;line-height:inherit;word-wrap:normal;background-color:#f6f8fa;border:0}.gist .markdown-body .csv-data td,.gist .markdown-body .csv-data th{padding:5px;overflow:hidden;font-size:12px;line-height:1;text-align:left;white-space:nowrap}.gist .markdown-body .csv-data .blob-num{padding:10px 8px 9px;text-align:right;background:#fff;border:0}.gist .markdown-body .csv-data tr{border-top:0}.gist .markdown-body .csv-data th{font-weight:600;background:#f6f8fa;border-top:0}.gist .pl-c{color:#6a737d}.gist .pl-c1,.gist .pl-s .pl-v{color:#005cc5}.gist .pl-e,.gist .pl-en{color:#6f42c1}.gist .pl-s .pl-s1,.gist .pl-smi{color:#24292e}.gist .pl-ent{color:#22863a}.gist .pl-k{color:#d73a49}.gist .pl-pds,.gist .pl-s,.gist .pl-s .pl-pse .pl-s1,.gist .pl-sr,.gist .pl-sr .pl-cce,.gist .pl-sr .pl-sra,.gist .pl-sr .pl-sre{color:#032f62}.gist .pl-smw,.gist .pl-v{color:#e36209}.gist .pl-bu{color:#b31d28}.gist .pl-ii{color:#fafbfc;background-color:#b31d28}.gist .pl-c2{color:#fafbfc;background-color:#d73a49}.gist .pl-c2:before{content:"^M"}.gist .pl-sr .pl-cce{font-weight:700;color:#22863a}.gist .pl-ml{color:#735c0f}.gist .pl-mh,.gist .pl-mh .pl-en,.gist .pl-ms{font-weight:700;color:#005cc5}.gist .pl-mi{font-style:italic;color:#24292e}.gist .pl-mb{font-weight:700;color:#24292e}.gist .pl-md{color:#b31d28;background-color:#ffeef0}.gist .pl-mi1{color:#22863a;background-color:#f0fff4}.gist .pl-mc{color:#e36209;background-color:#ffebda}.gist .pl-mi2{color:#f6f8fa;background-color:#005cc5}.gist .pl-mdr{font-weight:700;color:#6f42c1}.gist .pl-ba{color:#586069}.gist .pl-sg{color:#959da5}.gist .pl-corl{text-decoration:underline;color:#032f62}.gist .breadcrumb{font-size:16px;color:#586069}.gist .breadcrumb .separator{white-space:pre-wrap}.gist .breadcrumb .separator:after,.gist .breadcrumb .separator:before{content:" "}.gist .breadcrumb strong.final-path{color:#24292e}.gist strong{font-weight:bolder}.gist .editor-abort{display:inline;font-size:14px}.gist .blob-interaction-bar{position:relative;background-color:#f2f2f2;border-bottom:1px solid #e5e5e5}.gist .blob-interaction-bar:before{display:table;content:""}.gist .blob-interaction-bar:after{display:table;clear:both;content:""}.gist .blob-interaction-bar .octicon-search{position:absolute;top:10px;left:10px;font-size:12px;color:#586069}.gist .blob-filter{width:100%;padding:4px 20px 5px 30px;font-size:12px;border:0;border-radius:0;outline:none}.gist .blob-filter:focus{outline:none}.gist .html-blob{margin-bottom:15px}.gist .TagsearchPopover{width:inherit;max-width:600px}.gist .TagsearchPopover-content{max-height:300px}.gist .TagsearchPopover-list .TagsearchPopover-list-item:hover{background-color:#f6f8fa}.gist .TagsearchPopover-list .TagsearchPopover-list-item .TagsearchPopover-item:hover{text-decoration:none}.gist .TagsearchPopover-list .blob-code-inner{white-space:pre-wrap}.gist .linejump .linejump-input{width:340px;background-color:#fafbfc}.gist .linejump .btn,.gist .linejump .linejump-input{padding:10px 15px;font-size:16px}.gist .CopyBlock{line-height:20px;cursor:pointer}.gist .CopyBlock .octicon-clippy{display:none}.gist .CopyBlock:active,.gist .CopyBlock:focus,.gist .CopyBlock:hover{background-color:#fff;outline:none}.gist .CopyBlock:active .octicon-clippy,.gist .CopyBlock:focus .octicon-clippy,.gist .CopyBlock:hover .octicon-clippy{display:inline-block}.gist .blob-wrapper{overflow-x:auto;overflow-y:hidden}.gist .page-blob.height-full .blob-wrapper{overflow-y:auto}.gist .page-edit-blob.height-full .CodeMirror{height:300px}.gist .page-edit-blob.height-full .CodeMirror,.gist .page-edit-blob.height-full .CodeMirror-scroll{display:flex;flex-direction:column;flex:1 1 auto}.gist .blob-wrapper-embedded{max-height:240px;overflow-y:auto}.gist .diff-table{width:100%;border-collapse:initial}.gist .diff-table .line-comments{padding:10px;vertical-align:top;border-top:1px solid #e1e4e8}.gist .diff-table .line-comments:first-child+.empty-cell{border-left-width:1px}.gist .diff-table tr:not(:last-child) .line-comments{border-top:1px solid #e1e4e8;border-bottom:1px solid #e1e4e8}.gist .blob-num{width:1%;min-width:50px;padding-right:10px;padding-left:10px;font-family:SFMono-Regular,Consolas,Liberation Mono,Menlo,monospace;font-size:12px;line-height:20px;color:rgba(27,31,35,.3);text-align:right;white-space:nowrap;vertical-align:top;cursor:pointer;-webkit-user-select:none;-moz-user-select:none;-ms-user-select:none;user-select:none}.gist .blob-num:hover{color:rgba(27,31,35,.6)}.gist .blob-num:before{content:attr(data-line-number)}.gist .blob-num.non-expandable{cursor:default}.gist .blob-num.non-expandable:hover{color:rgba(27,31,35,.3)}.gist .blob-code{position:relative;padding-right:10px;padding-left:10px;line-height:20px;vertical-align:top}.gist .blob-code-inner{overflow:visible;font-family:SFMono-Regular,Consolas,Liberation Mono,Menlo,monospace;font-size:12px;color:#24292e;word-wrap:normal;white-space:pre}.gist .blob-code-inner .x-first{border-top-left-radius:.2em;border-bottom-left-radius:.2em}.gist .blob-code-inner .x-last{border-top-right-radius:.2em;border-bottom-right-radius:.2em}.gist .blob-code-inner.highlighted,.gist .blob-code-inner .highlighted{background-color:#fffbdd}.gist .blob-code-marker:before{padding-right:8px;content:attr(data-code-marker)}.gist .blob-code-marker-addition:before{content:"+ "}.gist .blob-code-marker-deletion:before{content:"- "}.gist .blob-code-marker-context:before{content:" "}.gist .soft-wrap .diff-table{table-layout:fixed}.gist .soft-wrap .blob-code{padding-left:18px;text-indent:-7px}.gist .soft-wrap .blob-code-inner{word-wrap:break-word;white-space:pre-wrap}.gist .soft-wrap .no-nl-marker{display:none}.gist .soft-wrap .add-line-comment{margin-left:-28px}.gist .blob-code-hunk,.gist .blob-num-expandable,.gist .blob-num-hunk{color:rgba(27,31,35,.7);vertical-align:middle}.gist .blob-num-expandable,.gist .blob-num-hunk{background-color:#dbedff}.gist .blob-code-hunk{padding-top:4px;padding-bottom:4px;background-color:#f1f8ff;border-width:1px 0}.gist .blob-expanded .blob-code,.gist .blob-expanded .blob-num{background-color:#fafbfc}.gist .blob-expanded+tr:not(.blob-expanded) .blob-code,.gist .blob-expanded+tr:not(.blob-expanded) .blob-num,.gist .blob-expanded .blob-num-hunk,.gist tr:not(.blob-expanded)+.blob-expanded .blob-code,.gist tr:not(.blob-expanded)+.blob-expanded .blob-num{border-top:1px solid #eaecef}.gist .blob-num-expandable{padding:0;font-size:12px;text-align:center}.gist .blob-num-expandable .diff-expander{display:block;width:auto;height:auto;padding:4px 11px 4px 10px;margin-right:-1px;color:#586069;cursor:pointer}.gist .blob-num-expandable .diff-expander .octicon{vertical-align:top}.gist .blob-num-expandable .directional-expander{display:block;width:auto;height:auto;margin-right:-1px;color:#586069;cursor:pointer}.gist .blob-num-expandable .single-expander{padding-top:4px;padding-bottom:4px}.gist .blob-num-expandable .diff-expander:hover,.gist .blob-num-expandable .directional-expander:hover{color:#fff;text-shadow:none;background-color:#0366d6;border-color:#0366d6}.gist .blob-code-addition{background-color:#e6ffed}.gist .blob-code-addition .x{color:#24292e;background-color:#acf2bd}.gist .blob-num-addition{background-color:#cdffd8;border-color:#bef5cb}.gist .blob-code-deletion{background-color:#ffeef0}.gist .blob-code-deletion .x{color:#24292e;background-color:#fdb8c0}.gist .blob-num-deletion{background-color:#ffdce0;border-color:#fdaeb7}.gist .is-selecting,.gist .is-selecting .blob-num{cursor:ns-resize !important}.gist .is-selecting .add-line-comment,.gist .is-selecting a{pointer-events:none;cursor:ns-resize !important}.gist .is-selecting .is-hovered .add-line-comment{opacity:0}.gist .is-selecting.file-diff-split,.gist .is-selecting.file-diff-split .blob-num{cursor:nwse-resize !important}.gist .is-selecting.file-diff-split .add-line-comment,.gist .is-selecting.file-diff-split .empty-cell,.gist .is-selecting.file-diff-split a{pointer-events:none;cursor:nwse-resize !important}.gist .selected-line{position:relative}.gist .selected-line:after{position:absolute;top:0;left:0;display:block;width:100%;height:100%;box-sizing:border-box;pointer-events:none;content:"";background:rgba(255,223,93,.2);mix-blend-mode:multiply}.gist .selected-line.selected-line-top:after{border-top:1px solid #ffd33d}.gist .selected-line.selected-line-bottom:after{border-bottom:1px solid #ffd33d}.gist .selected-line.selected-line-left:after,.gist .selected-line:first-child:after{border-left:1px solid #ffd33d}.gist .selected-line.selected-line-right:after,.gist .selected-line:last-child:after{border-right:1px solid #ffd33d}.gist .is-commenting .selected-line.blob-code:before{position:absolute;top:0;left:-1px;display:block;width:4px;height:100%;content:"";background:#0366d6}.gist .add-line-comment{position:relative;z-index:5;float:left;width:22px;height:22px;margin:-2px -10px -2px -20px;line-height:21px;color:#fff;text-align:center;text-indent:0;cursor:pointer;background-color:#0366d6;background-image:linear-gradient(#0372ef,#0366d6);border-radius:3px;box-shadow:0 1px 4px rgba(27,31,35,.15);opacity:0;transition:transform .1s ease-in-out;transform:scale(.8)}.gist .add-line-comment:hover{transform:scale(1)}.gist .add-line-comment:focus,.is-hovered .gist .add-line-comment{opacity:1}.gist .add-line-comment .octicon{vertical-align:text-top;pointer-events:none}.gist .add-line-comment.octicon-check{background:#333;opacity:1}.gist .inline-comment-form{border:1px solid #dfe2e5;border-radius:3px}.gist .inline-review-comment{margin-top:0 !important;margin-bottom:10px !important}.gist .inline-review-comment .gc:first-child+tr .blob-code,.gist .inline-review-comment .gc:first-child+tr .blob-num{padding-top:5px}.gist .inline-review-comment tr:last-child{border-bottom-right-radius:3px;border-bottom-left-radius:3px}.gist .inline-review-comment tr:last-child .blob-code,.gist .inline-review-comment tr:last-child .blob-num{padding-bottom:8px}.gist .inline-review-comment tr:last-child .blob-code:first-child,.gist .inline-review-comment tr:last-child .blob-num:first-child{border-bottom-left-radius:3px}.gist .inline-review-comment tr:last-child .blob-code:last-child,.gist .inline-review-comment tr:last-child .blob-num:last-child{border-bottom-right-radius:3px}.gist .timeline-inline-comments{width:100%;table-layout:fixed}.gist .show-inline-notes .inline-comments,.gist .timeline-inline-comments .inline-comments{display:table-row}.gist .inline-comments,.gist .inline-comments.is-collapsed{display:none}.gist .inline-comments .line-comments.is-collapsed{visibility:hidden}.gist .inline-comments .line-comments+.blob-num{border-left-width:1px}.gist .inline-comments .timeline-comment{margin-bottom:10px}.gist .comment-holder,.gist .inline-comments .inline-comment-form,.gist .inline-comments .inline-comment-form-container{max-width:780px}.gist .empty-cell+.line-comments,.gist .line-comments+.line-comments{border-left:1px solid #eaecef}.gist .inline-comment-form-container .inline-comment-form,.gist .inline-comment-form-container.open .inline-comment-form-actions{display:none}.gist .inline-comment-form-container .inline-comment-form-actions,.gist .inline-comment-form-container.open .inline-comment-form{display:block}.gist body.full-width .container,.gist body.full-width .container-lg,.gist body.full-width .container-xl,.gist body.split-diff .container,.gist body.split-diff .container-lg,.gist body.split-diff .container-xl{width:100%;max-width:none;padding-right:20px;padding-left:20px}.gist body.full-width .repository-content,.gist body.split-diff .repository-content{width:100%}.gist body.full-width .new-pr-form,.gist body.split-diff .new-pr-form{max-width:980px}.gist .file-diff-split{table-layout:fixed}.gist .file-diff-split .blob-code+.blob-num{border-left:1px solid #f6f8fa}.gist .file-diff-split .blob-code-inner{word-wrap:break-word;white-space:pre-wrap}.gist .file-diff-split .empty-cell{cursor:default;background-color:#fafbfc;border-right-color:#eaecef}@media (max-width:1280px){.gist .file-diff-split .write-selected .comment-form-head{margin-bottom:48px !important}.gist .file-diff-split markdown-toolbar{position:absolute;right:8px;bottom:-40px}}.gist .submodule-diff-stats .octicon-diff-removed{color:#cb2431}.gist .submodule-diff-stats .octicon-diff-renamed{color:#677a85}.gist .submodule-diff-stats .octicon-diff-modified{color:#d0b44c}.gist .submodule-diff-stats .octicon-diff-added{color:#28a745}.gist .BlobToolbar{left:-17px}.gist .BlobToolbar-dropdown{margin-left:-2px}.gist .code-navigation-banner{background:linear-gradient(180deg,rgba(242,248,254,0),rgba(242,248,254,.47))}.gist .code-navigation-banner .code-navigation-banner-illo{background-image:url(code-navigation-banner-illo.svg);background-repeat:no-repeat;background-position:50%}.gist .pl-token.active,.gist .pl-token:hover{cursor:pointer;background:#ffea7f}.gist .task-list-item{list-style-type:none}.gist .task-list-item label{font-weight:400}.gist .task-list-item.enabled label{cursor:pointer}.gist .task-list-item+.task-list-item{margin-top:3px}.gist .task-list-item .handle{display:none}.gist .task-list-item-checkbox{margin:0 .2em .25em -1.6em;vertical-align:middle}.gist .reorderable-task-lists .markdown-body .contains-task-list{padding:0}.gist .reorderable-task-lists .markdown-body li:not(.task-list-item){margin-left:26px}.gist .reorderable-task-lists .markdown-body ol:not(.contains-task-list) li,.gist .reorderable-task-lists .markdown-body ul:not(.contains-task-list) li{margin-left:0}.gist .reorderable-task-lists .markdown-body li p{margin-top:0}.gist .reorderable-task-lists .markdown-body .task-list-item{padding-right:15px;padding-left:42px;margin-right:-15px;margin-left:-15px;border:1px solid transparent}.gist .reorderable-task-lists .markdown-body .task-list-item+.task-list-item{margin-top:0}.gist .reorderable-task-lists .markdown-body .task-list-item .contains-task-list{padding-top:4px}.gist .reorderable-task-lists .markdown-body .task-list-item .handle{display:block;float:left;width:20px;padding:2px 0 0 2px;margin-left:-43px;opacity:0}.gist .reorderable-task-lists .markdown-body .task-list-item .drag-handle{fill:#333}.gist .reorderable-task-lists .markdown-body .task-list-item.hovered>.handle{opacity:1}.gist .reorderable-task-lists .markdown-body .task-list-item.is-dragging{opacity:0}.gist .review-comment-contents .markdown-body .task-list-item{padding-left:42px;margin-right:-12px;margin-left:-12px;border-top-left-radius:3px;border-bottom-left-radius:3px}.gist .review-comment-contents .markdown-body .task-list-item.hovered{border-left-color:#ededed}.gist .highlight{padding:0;margin:0;font-family:SFMono-Regular,Consolas,Liberation Mono,Menlo,monospace;font-size:12px;font-weight:400;line-height:1.4;color:#333;background:#fff;border:0}.gist .octospinner,.gist .render-viewer-error,.gist .render-viewer-fatal,.gist .render-viewer-invalid{display:none}.gist iframe.render-viewer{width:100%;height:480px;overflow:hidden;border:0}.gist code,.gist pre{font-family:SFMono-Regular,Consolas,Liberation Mono,Menlo,monospace !important}.gist .gist-meta{padding:10px;overflow:hidden;font:12px -apple-system,BlinkMacSystemFont,Segoe UI,Helvetica,Arial,sans-serif,Apple Color Emoji,Segoe UI Emoji;color:#586069;background-color:#f7f7f7;border-radius:0 0 3px 3px}.gist .gist-meta a{font-weight:600;color:#666;text-decoration:none;border:0}.gist .gist-data{overflow:auto;word-wrap:normal;background-color:#fff;border-bottom:1px solid #ddd;border-radius:3px 3px 0 0}.gist .gist-file{margin-bottom:1em;font-family:SFMono-Regular,Consolas,Liberation Mono,Menlo,monospace;border:1px solid;border-color:#ddd #ddd #ccc;border-radius:3px}.gist .gist-file article{padding:6px}.gist .gist-file .scroll .gist-data{position:absolute;top:0;right:0;bottom:30px;left:0;overflow:scroll}.gist .gist-file .scroll .gist-meta{position:absolute;right:0;bottom:0;left:0}.gist .blob-num{min-width:inherit}.gist .blob-code,.gist .blob-num{padding:1px 10px !important;background:transparent}.gist .blob-code{text-align:left;border:0}.gist .blob-wrapper table{border-collapse:collapse}.gist table,.gist table tr,.gist table tr td,.gist table tr th{border-collapse:collapse}.gist .blob-wrapper tr:first-child td{padding-top:4px}.gist .markdown-body .anchor{display:none}"""

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
        style = gh_css_style,
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
