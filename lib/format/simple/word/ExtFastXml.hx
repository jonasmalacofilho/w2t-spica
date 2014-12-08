/*
 * Modified haxe.xml.ExtFastXml
 *
 * haxe.xml.ExtFastXml
 * Copyright (C)2005-2012 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
package format.simple.word;

private class NodeAccess implements Dynamic<ExtFastXml> {

	var __x : Xml;
    var __n : Null<String->String>;

	public function new( x : Xml, nameMod ) {
		__x = x;
        __n = nameMod;
	}

	public function resolve( name : String ) : ExtFastXml {
        if (__n != null)
            name = __n(name);
		var x = __x.elementsNamed(name).next();
		if( x == null ) {
			var xname = if( __x.nodeType == Xml.Document ) "Document" else __x.nodeName;
			throw xname+" is missing element "+name;
		}
		return new ExtFastXml(x, __n);
	}

}

private class AttribAccess implements Dynamic<String> {

	var __x : Xml;
    var __n : Null<String->String>;

	public function new( x : Xml, nameMod ) {
		__x = x;
        __n = nameMod;
	}

	public function resolve( name : String ) : String {
        if (__n != null)
            name = __n(name);
		if( __x.nodeType == Xml.Document )
			throw "Cannot access document attribute "+name;
		var v = __x.get(name);
		if( v == null )
			throw __x.nodeName+" is missing attribute "+name;
		return v;
	}

}

private class HasAttribAccess implements Dynamic<Bool> {

	var __x : Xml;
    var __n : Null<String->String>;

	public function new( x : Xml, nameMod ) {
		__x = x;
        __n = nameMod;
	}

	public function resolve( name : String ) : Bool {
        if (__n != null)
            name = __n(name);
		if( __x.nodeType == Xml.Document )
			throw "Cannot access document attribute "+name;
		return __x.exists(name);
	}

}

private class HasNodeAccess implements Dynamic<Bool> {

	var __x : Xml;
    var __n : Null<String->String>;

	public function new( x : Xml, nameMod ) {
		__x = x;
        __n = nameMod;
	}

	public function resolve( name : String ) : Bool {
        if (__n != null)
            name = __n(name);
		return __x.elementsNamed(name).hasNext();
	}

}

private class NodeListAccess implements Dynamic<List<ExtFastXml>> {

	var __x : Xml;
    var __n : Null<String->String>;

	public function new( x : Xml, nameMod ) {
		__x = x;
        __n = nameMod;
	}

	public function resolve( name : String ) : List<ExtFastXml> {
        if (__n != null)
            name = __n(name);
		var l = new List();
		for( x in __x.elementsNamed(name) )
			l.add(new ExtFastXml(x, __n));
		return l;
	}

}

class ExtFastXml {

	public var x(default,null) : Xml;
	public var name(get,null) : String;
	public var innerData(get,null) : String;
	public var innerHTML(get,null) : String;
	public var node(default,null) : NodeAccess;
	public var nodes(default,null) : NodeListAccess;
	public var att(default,null) : AttribAccess;
	public var has(default,null) : HasAttribAccess;
	public var hasNode(default,null) : HasNodeAccess;
	public var elements(get,null) : Iterator<ExtFastXml>;

    var nameMod : Null<String->String>;

	public function new( x : Xml, ?nameMod : String -> String ) {
		if( x.nodeType != Xml.Document && x.nodeType != Xml.Element )
			throw "Invalid nodeType "+x.nodeType;
        this.nameMod = nameMod;
		this.x = x;
		node = new NodeAccess(x, nameMod);
		nodes = new NodeListAccess(x, nameMod);
		att = new AttribAccess(x, nameMod);
		has = new HasAttribAccess(x, nameMod);
		hasNode = new HasNodeAccess(x, nameMod);
	}

	function get_name() {
		return if( x.nodeType == Xml.Document ) "Document" else x.nodeName;
	}

	function get_innerData() {
		var it = x.iterator();
		if( !it.hasNext() )
			throw name+" does not have data";
		var v = it.next();
		var n = it.next();
		if( n != null ) {
			// handle <spaces>CDATA<spaces>
			if( v.nodeType == Xml.PCData && n.nodeType == Xml.CData && StringTools.trim(v.nodeValue) == "" ) {
				var n2 = it.next();
				if( n2 == null || (n2.nodeType == Xml.PCData && StringTools.trim(n2.nodeValue) == "" && it.next() == null) )
					return n.nodeValue;
			}
			throw name+" does not only have data";
		}
		if( v.nodeType != Xml.PCData && v.nodeType != Xml.CData )
			throw name+" does not have data";
		return v.nodeValue;
	}

	function get_innerHTML() {
		var s = new StringBuf();
		for( x in x )
			s.add(x.toString());
		return s.toString();
	}

	function get_elements() {
		var it = x.elements();
		return {
			hasNext : it.hasNext,
			next : function() {
				var x = it.next();
				if( x == null )
					return null;
				return new ExtFastXml(x, nameMod);
			}
		};
	}
}

