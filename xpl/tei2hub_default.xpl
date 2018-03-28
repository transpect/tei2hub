<?xml version="1.0" encoding="utf-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tr="http://transpect.io" 
  version="1.0"
  name="tei2hub-driver">

  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <p>Following modes are defined in the XSLT:</p>
    <dl>
      <dt>tei2hub</dt>
      <dd>Creates the document structure and maps most of the elements from TEI to HUB.</dd>
      <dt>clean-up</dt>
      <dd>A clean up mode to postprocess the results e.g. grouping contribs. Should always run after mode <span class="dependency">tei2hub</span> ran.</dd>
    </dl>
  </p:documentation>

	<p:option name="debug" required="false" select="'no'"/>
	<p:option name="debug-dir-uri"/>

	<p:input port="source" primary="true"/>

	<p:input port="parameters" kind="parameter" primary="true"/>
	<p:input port="stylesheet"/>

	<p:output port="result" primary="true">
    <p:pipe port="result" step="clean-up"/>
  </p:output>

  <p:output port="report" sequence="true">
    <p:pipe port="report" step="tei2hub"/>
    <p:pipe port="report" step="clean-up"/>
  </p:output>

	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<p:import href="http://transpect.io/xproc-util/xslt-mode/xpl/xslt-mode.xpl"/>
  <p:import href="http://transpect.io/xproc-util/xml-model/xpl/prepend-xml-model.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  
  <p:identity name="create-model">
    <p:input port="source">
      <p:inline>
        <c:models>
          <c:model href="http://www.le-tex.de/resource/schema/hub/1.2/hub.rng"
            type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"/>
        </c:models>
      </p:inline>
    </p:input>
  </p:identity>
  
  <p:sink/>
  

  <tr:xslt-mode prefix="tei2hub/10" mode="tei2hub" name="tei2hub">
    <p:input port="source">
      <p:pipe step="tei2hub-driver" port="source"/>
    </p:input>
    <p:input port="models">
      <p:empty/>
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="tei2hub-driver" port="stylesheet"/>
    </p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>

  <tr:xslt-mode prefix="tei2hub/75" mode="clean-up" name="clean-up">
    <p:input port="stylesheet">
      <p:pipe step="tei2hub-driver" port="stylesheet"/>
    </p:input>
    <p:input port="models">
      <p:empty/>
    </p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>

  <p:delete match="@srcpath" name="drop-srcpaths"/>
  
  <tr:prepend-xml-model>
    <p:input port="models"><p:pipe step="create-model" port="result"/></p:input>
  </tr:prepend-xml-model>
  
  <tr:store-debug pipeline-step="tei2hub/result-with-model">
    <p:with-option name="active" select="$debug" />
    <p:with-option name="base-uri" select="$debug-dir-uri" />
  </tr:store-debug>
  
  <p:sink/>

</p:declare-step>
