package format.simple.word;

import format.simple.word.Document;
import haxe.zip.Reader.readZip;
import haxe.zip.Reader.unzip;
using StringTools;
using Std;
using Lambda;

class DocxReader {

    var zip:List<haxe.zip.Entry>;

    function new(z)
    {
        zip = z;
    }

    function openXml(name)
    {
        var e = Lambda.find(zip, function (e) return e.fileName == 'word/$name');
        if (e == null)
            throw 'Missing xml $name';

        function wPreffix(n:String)
        {
            return n.indexOf(":") >= 0 ? n : "w:" + n;
        }
        return new ExtFastXml(Xml.parse(unzip(e).toString()), wPreffix);
    }

    function readBoolAtt(node:ExtFastXml, name):Null<Bool>
    {
        if (!node.has.resolve(name)) {
            return null;
        }
        else {
            return switch (node.att.resolve(name)) {
            case "on", "1", "true": true;
            case "off", "0", "false": false;
            case all: throw 'Assert: $all';
            }
        }
    }

    function readRunProps(rPrNode:ExtFastXml)
    {
        var ret = [];
        for (el in rPrNode.elements) {
            switch (el.name) {
            case "w:b":
                ret.push(PBold(readBoolAtt(el, "val") != false));
            case "w:i":
                ret.push(PItalic(readBoolAtt(el, "val") != false));
            case "w:rFonts":
                var ascii = el.has.ascii ? el.att.ascii : null;
                var hAnsi = el.has.hAnsi ? el.att.hAnsi : null;
                var cs = el.has.cs ? el.att.cs : null;
                var eastAsia = el.has.eastAsia ? el.att.eastAsia : null;
                ret.push(PFonts(ascii, hAnsi, cs, eastAsia));
            case "w:rStyle":
                ret.push(PStyleRef(el.att.val));
            case all:
            }
        }
        return ret;
    }

    function readParProps(pPrNode:ExtFastXml)
    {
        var ret = [];
        for (el in pPrNode.elements) {
            switch (el.name) {
            case "w:rPr":
                ret = ret.concat(readRunProps(el));
            case "w:pStyle":
                ret.push(PStyleRef(el.att.val));
            case all:
            }
        }
        return ret;
    }

    function readStyle(styleNode:ExtFastXml):Null<Style>
    {
        if (!~/paragraph|character/.match(styleNode.att.type))
            return null;

        if (!styleNode.hasNode.pPr && !styleNode.hasNode.rPr)
            return null;

        var ret:Style = {
            name : styleNode.att.styleId,
            type : styleNode.att.type,
            basedOn : styleNode.hasNode.basedOn ? styleNode.node.basedOn.att.val : null,
            props : []
        };

        if (styleNode.hasNode.pPr)
            ret.props = ret.props.concat(readParProps(styleNode.node.pPr));
        if (styleNode.hasNode.rPr)
            ret.props = ret.props.concat(readRunProps(styleNode.node.rPr));

        return ret;
    }

    function readDocDefaults(stylesNode:ExtFastXml)
    {
        if (!stylesNode.hasNode.docDefaults)
            return { parDefault : [], runDefault : [] };

        var ret = cast {};
        var defNode = stylesNode.node.docDefaults;

        if (defNode.hasNode.pPrDefault && defNode.node.pPrDefault.hasNode.pPr)
            ret.parDefault = readParProps(defNode.node.pPrDefault.node.pPr);
        else
            ret.parDefault = [];

        if (defNode.hasNode.rPrDefault && defNode.node.rPrDefault.hasNode.rPr)
            ret.runDefault = readRunProps(defNode.node.rPrDefault.node.rPr);
        else
            ret.runDefault = [];

        return ret;
    }

    function readRun(rNode:ExtFastXml)
    {
        var run = cast {};
        run.props = rNode.hasNode.rPr ? readRunProps(rNode.node.rPr) : [];
        var ccnt = 0;  // found content count, should be 1
        if (rNode.hasNode.t) {
            var tNode = rNode.node.t;
            var text = tNode.innerData.htmlUnescape();
            if (tNode.x.get("xml:space") != "preserve")
                text = text.trim();
            run.content = CText(text);
            ccnt++;
        }
        if (rNode.hasNode.footnoteReference) {
            run.content = CFootnoteRef(rNode.node.footnoteReference.att.id.parseInt());
            ccnt++;
        }
        if (ccnt != 1)
            throw 'Assert: ($ccnt) ${rNode.x}';
        return run;
    }

    function readPar(pNode:ExtFastXml)
    {
        var par = cast {};
        par.props = pNode.hasNode.pPr ? readParProps(pNode.node.pPr) : [];
        par.runs = [];
        for (rNode in pNode.nodes.r) {
            par.runs.push(readRun(rNode));
        }
        return par;
    }

    function readStyles()
    {
        var stylesNode = openXml("styles.xml").node.styles;
        var ret = {
            docDefaults : null,
            styles : null
        };
        ret.docDefaults = readDocDefaults(stylesNode);
        var styles = stylesNode.nodes.style.map(readStyle);
        ret.styles = styles.filter(function (x) return x != null).array();
        return ret;
    }

    function readFootnotes()
    {
        var notesNode = openXml("footnotes.xml").node.footnotes;
        return cast {};
    }

    function readBody()
    {
        var bodyNode = openXml("document.xml").node.document.node.body;
        var ret = { pars : [] };
        for (pNode in bodyNode.nodes.p) {
            ret.pars.push(readPar(pNode));
        }
        return ret;
    }
    function readDocument()
    {
        return { styles : readStyles(), body : readBody() };
    }

    function read()
    {
        return readDocument();
    }

    public static function readDocx(docx:haxe.io.Input):Document
    {
        var r = new DocxReader(readZip(docx));
        return r.read();
    }

}

