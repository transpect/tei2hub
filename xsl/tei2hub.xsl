<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:tei="http://www.tei-c.org/ns/1.0" 
  xmlns:tei2hub="http://transpect.io/tei2hub"
  xmlns:hub="http://transpect.io/hub"  
  xmlns:saxon="http://saxon.sf.net/"
  xmlns:hub2htm="http://transpect.io/hub2htm"
  xmlns:xlink="http://www.w3.org/1999/xlink" 
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:tr="http://transpect.io"
  xmlns:mml="MathML Namespace Declaration"
  xmlns="http://docbook.org/ns/docbook"
  xpath-default-namespace="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tr hub2htm saxon tei2hub tei xsl xs" 
  version="2.0">
  
  <!-- This module expects a TEI document -->
  
  <xsl:param name="debug" select="'yes'"/>
  <xsl:param name="debug-dir-uri" select="'debug'"/>
  
  <xsl:variable name="root" select="/" as="document-node()"/>
  <xsl:param name="sections-to-numbered-secs" as="xs:boolean" select="false()">
    <!-- if set true(): sections are nested as sec1/sec2 etc.-->
  </xsl:param>
  
<!--  <xsl:key name="rule-by-name" match="css:rule" use="@name"/>-->
  <xsl:key name="by-id" match="*[@id | @xml:id]" use="@id | @xml:id"/>
  <xsl:key name="link-by-anchor" match="ref | link | ptr" use="@target"/>
  
  <!-- identity template -->
  <xsl:template match="* | @*" mode="tei2hub clean-up" priority="-0.5">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="processing-instruction()" mode="tei2hub clean-up" priority="2">
    <xsl:copy-of select="."/>
  </xsl:template>
  
  <xsl:template match="@rend" mode="tei2hub">
    <xsl:attribute name="role" select="."/>
  </xsl:template>
  
  <xsl:template match="@* | node()" mode="css:unhandled" priority="-1.5">
    <xsl:value-of select="local-name()"/>
  </xsl:template>

  <xsl:template match="*" mode="tei2hub" priority="-0.25">
    <xsl:message>tei2hub: unhandled: <xsl:apply-templates select="." mode="css:unhandled"/> </xsl:message>
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
    
  <xsl:template match="@srcpath| @css:version | @xml:id | @xml:base" mode="tei2hub">
    <xsl:copy/>
  </xsl:template>

  <xsl:template match="@*" mode="tei2hub" priority="-1.5">
    <xsl:message>tei2hub: unhandled attr: <xsl:apply-templates select="." mode="css:unhandled"/>
    </xsl:message>
  </xsl:template>
  
  <!-- TODO: alternative images-->
  
  <xsl:template match="@rendition" mode="tei2hub">
    <xsl:attribute name="condition" select="."/>
  </xsl:template>
  
  <xsl:template match="@xml:lang | @lang" mode="tei2hub">
     <xsl:attribute name="xml:lang" select="." />
  </xsl:template>

  <xsl:template match="/*/@source-dir-uri" mode="tei2hub"/>
  
  <xsl:template match="/*/@css:rule-selection-attribute" mode="tei2hub">
    <xsl:attribute name="{name()}" select="'role'" />
  </xsl:template>
  
  <xsl:template match="/*/@*[name() = ('version')]" mode="tei2hub">
    <xsl:attribute name="version" select="'5.1-variant le-tex_Hub-1.2'" />
  </xsl:template>

  <xsl:template match="/TEI" mode="tei2hub">
    <book>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </book>
  </xsl:template>
  
  <xsl:template match="bibl[@type = 'source'] | unclear" mode="tei2hub">
    <bibliomisc>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="node()" mode="#current"/>
    </bibliomisc>
  </xsl:template>
  
  <xsl:template match="bibl/@type" mode="tei2hub">
    <xsl:attribute name="role" select="."></xsl:attribute>
  </xsl:template>

  <xsl:template match="bibl[not(@type = 'source')]" mode="tei2hub">
    <bibliomixed>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="node()" mode="#current"/>
    </bibliomixed>
  </xsl:template>

  <xsl:template match="p//bibl[@type = 'citation']" mode="tei2hub">
    <citation>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </citation>
  </xsl:template>
  
  <xsl:template match="postscript/bibl[@type = 'copyright']" mode="tei2hub" priority="3"> 
    <para role="copyright">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </para>
  </xsl:template>
  
  <xsl:template match="biblFull" mode="tei2hub">
    <biblioentry>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </biblioentry>
  </xsl:template>
  

  <xsl:function name="tei2hub:is-ref-list" as="xs:boolean">
    <xsl:param name="elt" as="element(div)"/>
    <xsl:sequence select="exists($elt[self::div[every $elt in * satisfies ($elt[self::listBibl[not(head)]])]])"/>
  </xsl:function>

  <xsl:template match="div[tei2hub:is-ref-list(.)]" mode="tei2hub" priority="2">
    <bibliodiv>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </bibliodiv>
  </xsl:template>

  <xsl:template match="listBibl" mode="tei2hub" priority="2">
    <xsl:variable name="target" as="xs:string" select="if (..[self::div[@type = 'bibliography']]) 
                                                       then 'bibliodiv'
                                                       else
                                                        if (count(ancestor::listBibl) ge 1)
                                                        then 'bibliolist'
                                                        else 'bibliography'"/>
    <xsl:element name="{$target}">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="div[@type = 'bibliography'][head][listBibl | bibl]" mode="tei2hub" priority="4">
    <xsl:element name="{if (ancestor::div[@type = 'bibliography']) then 'bibliodiv' else 'bibliography'}">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="table/@rendition[matches(., '\.(png|jpe?g)$', 'i')]" mode="tei2hub">
    <alt>
      <xsl:for-each select="tokenize(., ' ')">
        <graphic xlink:href="{.}"/>
      </xsl:for-each>
    </alt>
  </xsl:template>
  
  <xsl:template match="table" mode="tei2hub" priority="3">
    <xsl:element name="{if (head or caption or note or postscript) then 'table' else 'informaltable'}">
      <xsl:apply-templates select="@* except (@rend, @rendition), head" mode="#current"/>
      <xsl:apply-templates select="@rendition" mode="#current"/>
      <tgroup cols="{count(colgroup/col)}">
        <xsl:call-template name="add-colspec"/>
        <xsl:apply-templates select="thead, tbody, tfoot" mode="#current"/>
      </tgroup>
      <xsl:if test="caption or note or postscript">
        <caption>
          <xsl:apply-templates select="caption/node(), note, postscript " mode="#current"/>
        </caption>
      </xsl:if>
    </xsl:element>
  </xsl:template>
  
 <xsl:param name="create-colspec" select="true()"/>
  
 <xsl:template name="add-colspec">
   <xsl:if test="$create-colspec = (true(), 'yes')">
     <xsl:for-each select="colgroup/col">
       <xsl:variable name="colnumber" select="position()"/>
       <colspec>
         <xsl:attribute name="colwidth" select="current()/@css:width"/>
         <xsl:attribute name="colnum" select="$colnumber"/>
         <xsl:attribute name="colname" select="concat('col', $colnumber)"/>
       </colspec>
     </xsl:for-each>
   </xsl:if>
  </xsl:template>
  
  <xsl:template match="table/postscript" mode="tei2hub" priority="2">
   <xsl:apply-templates select="node()" mode="#current"/>
  </xsl:template>

  <xsl:template match="teiHeader" mode="tei2hub">
    <info><xsl:apply-templates select="@*, node()" mode="#current"/></info>
  </xsl:template>
  
  <xsl:template match="text | fileDesc |textClass | profileDesc | docTitle | seriesStmt | publicationStmt | opener | encodingDesc | editionStmt/p | text/front | text/body | text/back | opener[idno]" mode="tei2hub">
    <xsl:apply-templates select="node()" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="editionStmt" mode="tei2hub">
    <edition>
      <xsl:apply-templates select="node()" mode="#current"/>
    </edition>
  </xsl:template>

  <xsl:template match="seriesStmt/biblScope[@unit = 'volume']" mode="tei2hub">
    <volumenum>
      <xsl:apply-templates select="node()" mode="#current"/>
    </volumenum>
  </xsl:template>


  <xsl:template match="seriesStmt/biblScope[@unit = 'issue']" mode="tei2hub">
    <issuenum>
      <xsl:apply-templates select="node()" mode="#current"/>
    </issuenum>
  </xsl:template>

  <xsl:template match="seriesStmt/idno[@type = ('issn', 'doi', 'poi', 'isbn')]" mode="tei2hub">
    <biblioid>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </biblioid>
  </xsl:template>

  <xsl:template match="publicationStmt/idno" mode="tei2hub">
    <xsl:if test="normalize-space()">
      <book-id book-id-type="doi">
        <xsl:apply-templates select="node()" mode="#current"/>
      </book-id>
    </xsl:if>
  </xsl:template>

  <xsl:template match="persName[@type = 'author']/roleName" mode="tei2hub" priority="3">
    <xsl:element name="{if (matches(., '(Dr|Prof)\.')) then 'prefix' else 'role'}">
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="publicationStmt/date" mode="tei2hub">
    <xsl:if test="normalize-space()">
      <pubdate>
        <xsl:apply-templates select="@*, node()" mode="#current"/>
      </pubdate>
    </xsl:if>
  </xsl:template>

  <xsl:template match="publicationStmt/publisher | titlePage/docImprint" mode="tei2hub">
    <publisher>
      <publishername>
        <xsl:apply-templates select="@*, node()" mode="#current"/>
      </publishername>
      <xsl:if test="..[normalize-space(pubPlace[1])]">
        <address>
          <xsl:value-of select="normalize-space(../pubPlace[1])"/>
        </address>
      </xsl:if>
    </publisher>
  </xsl:template>

  <xsl:template match="titleStmt" mode="tei2hub">
    <xsl:if test="editor">
      <authorgroup>
        <xsl:apply-templates select="editor" mode="#current"/>
      </authorgroup>
    </xsl:if>
    <xsl:if test="title[@type = 'main']">
        <title>
          <xsl:value-of select="title[@type = 'main']"/>
        </title>
        <xsl:if test="title[@type = 'sub']">
          <subtitle>
            <xsl:value-of select="title[@type = 'sub']"/>
          </subtitle>
        </xsl:if>
        <xsl:if test="title[@type = 'issue-title']">
          <subtitle role="issue-title">
            <xsl:value-of select="title[@type = 'issue-title']"/>
          </subtitle>
        </xsl:if>
    </xsl:if>
    <!-- needed for metadata. other information is retrieved differently -->
  </xsl:template>

  <xsl:template match="seriesStmt/idno/@subtype" mode="tei2hub">
    <xsl:attribute name="role" select="."/>
  </xsl:template>

  <xsl:template match="seriesStmt/title[@type = 'main'] | docTitle/titlePart[@type = 'main']" mode="tei2hub">
   <title><xsl:apply-templates select="@*, node()" mode="#current"/></title>
  </xsl:template>

  <xsl:template match="seriesStmt/title[@type = 'sub'] | docTitle/titlePart[@type = 'sub']" mode="tei2hub">
   <subtitle><xsl:apply-templates select="@*, node()" mode="#current"/></subtitle>
  </xsl:template>

  <xsl:template match="publicationStmt/distributor |  publicationStmt/pubPlace | sourceDesc | styleDefDecl | langUsage" mode="tei2hub">
    <!-- perhaps later -->
  </xsl:template>
  
  <xsl:template match="keywords" mode="tei2hub">
    <keywordset role="{if (contains(@scheme, 'hub.rng')) then 'hub' else 'keywords'}">
      <xsl:apply-templates select="node()" mode="#current"/>
    </keywordset>
  </xsl:template>
  
  <xsl:template match="keywords/term" mode="tei2hub">
    <keyword>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </keyword>
  </xsl:template>

  <xsl:template match="keywords/term/@key" mode="tei2hub">
    <xsl:attribute name="role" select="."/>
  </xsl:template>

  <xsl:template match="css:rules | css:rule" mode="tei2hub">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
 
  <xsl:template match="*:tabs | *:tabs/*:tab | css:attic" mode="tei2hub" priority="2">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="titlePage" mode="tei2hub"/>
  
  <xsl:variable name="frontmatter-parts" as="xs:string+"
    select="('title-page', 'copyright-page', 'dedication', 'about-contrib', 'about-book', 'series', 'additional-info', 'motto', 'halftitle')"/>
  
  <xsl:template match="div[@rend = $frontmatter-parts]" mode="tei2hub" priority="2">
    <colophon role="{@type}">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </colophon>
  </xsl:template>
  
  <xsl:template match="div[@type = 'appendix']" mode="tei2hub" priority="2">
    <appendix>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </appendix>
  </xsl:template>

  <xsl:template match="div[@type = 'acknowledgements']" mode="tei2hub" priority="2">
    <acknowledgements>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </acknowledgements>
  </xsl:template>

  <xsl:template match="divGen[@type = 'toc']" mode="tei2hub" priority="2">
    <toc>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </toc>
  </xsl:template>

  <xsl:template match="divGen[@type = 'index']" mode="tei2hub" priority="2">
    <index>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </index>
  </xsl:template>

  <xsl:template match="divGen[@type = 'index']/@subtype" mode="tei2hub" priority="2">
      <xsl:attribute name="type" select="." />
  </xsl:template>

<!--  <xsl:template match="div[@type = 'dedication']" mode="tei2hub">
    <dedication book-part-type="{@type}">
      <xsl:call-template name="named-book-part-meta"/>
      <xsl:call-template name="named-book-part-body"/>
      <xsl:call-template name="book-part-back"/>
    </dedication>
  </xsl:template>-->
  
  <xsl:template match="editor | author" mode="tei2hub" priority="2">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="byline/location" mode="tei2hub" priority="2">
    <xsl:choose>
      <xsl:when test="address">
        <xsl:apply-templates select="node()" mode="#current"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="address">
          <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="ref | ptr" mode="tei2hub" priority="2">
    <link>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </link>
  </xsl:template>

  <xsl:template match="ref/@target | ptr/@target" mode="tei2hub" priority="2">
    <xsl:attribute name="{if (starts-with(., '#')) then 'linkend' else 'xlink:href'}" select="replace(., '^#', '')"/>
  </xsl:template>

  
  <xsl:template match="docAuthor" mode="tei2hub">
    <xsl:choose>
      <xsl:when test="ancestor::*[self::title-page]">
        <para>
          <xsl:apply-templates select="@*, node()" mode="#current"/>
        </para>
      </xsl:when>
      <xsl:otherwise>
        <author>
          <xsl:apply-templates select="@*" mode="#current"/>
          <personname>
            <xsl:apply-templates select="node()" mode="#current"/>
          </personname>
        </author>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="byline/@rend" mode="tei2hub">
    <!-- perhaps extract contrib-type from style name -->
  </xsl:template>

  <xsl:template match="byline" mode="tei2hub">
    <xsl:choose>
      <xsl:when test="not(persName)">
        <author>
          <xsl:apply-templates select="@*, node()" mode="#current"/>
        </author>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each-group select="node()" group-starting-with="persName">
          <xsl:for-each-group select="current-group()" group-adjacent="boolean(.[self::persName | self::location | self::graphic])">
          <xsl:choose>
            <xsl:when test="current-grouping-key()">
              <xsl:element name="{(current-group()[self::persName]/@type, 'author')[1]}">
                  <xsl:apply-templates select="current-group()" mode="#current"/>
              </xsl:element>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="current-group()" mode="#current"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each-group>
      </xsl:for-each-group>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="divGen[@type = 'toc']" mode="tei2hub">
    <toc>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </toc>
  </xsl:template>
  
  <xsl:template match="preface | div[@type = 'preface'][matches(@rend, '^p_h')]" mode="tei2hub" priority="2">
    <preface>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </preface>
  </xsl:template>
  
  <xsl:template match="add | emph | orig | unclear| orgName | placeName | state | underline" mode="tei2hub">
    <xsl:element name="phrase">
      <xsl:attribute name="role" select="local-name()"/>
      <xsl:apply-templates select="@* except @rend, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="seg | hi" mode="tei2hub">
    <xsl:element name="phrase">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="@rendition[. = ('subscript', 'superscript')]" mode="tei2hub"/>
  
  <xsl:template match="hi[@rendition = ('subscript', 'superscript')] | hi[@specific-use = ('subscript', 'superscript')]" mode="tei2hub">
    <xsl:element name="{@rendition}">
     <xsl:apply-templates select="@* except @rendition, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="persName[surname and forename] | name" mode="tei2hub" priority="2">
    <personname>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="surname, forename, node() except (text()[1], surname, forename)" mode="#current"/>
      <xsl:if test="node()[1][self::text()[matches(., '\S')]]">
        <honorific>
          <xsl:value-of select="normalize-space(text()[1])"/>
        </honorific>
      </xsl:if>
    </personname>
  </xsl:template>
  
  <xsl:template match="persName[not(surname) and not(forename)]" mode="tei2hub" priority="2">
    <personname>
      <xsl:apply-templates select="@*" mode="#current"/>
      <othername>
         <xsl:apply-templates select="node()" mode="#current"/>
      </othername>
    </personname>
  </xsl:template>
  
  <xsl:template match="surname" mode="tei2hub">
    <surname>
      <xsl:apply-templates select="@* except @rend" mode="#current"/>
      <xsl:value-of select="normalize-space(text())"/>
    </surname>
  </xsl:template>
  
  <xsl:template match="forename" mode="tei2hub">
    <givenname>
      <xsl:apply-templates select="@* except @rend" mode="#current"/>
      <xsl:value-of select="normalize-space(text())"/>
    </givenname>
  </xsl:template>
   
  <xsl:template match="formula/@n" mode="tei2hub"/>
  
  <xsl:template match="formula" mode="tei2hub">
    <xsl:element name="{if (@rend = 'inline') then 'inlineequation' else 'equation'}">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="floatingText[@type = 'marginal']" mode="tei2hub">
    <sidebar>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </sidebar>
  </xsl:template>
  
  <xsl:template match="floatingText[not(@type = 'marginal')]" mode="tei2hub">
    <div role="{@type}">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </div>
  </xsl:template>

  <xsl:template match="floatingText/front | floatingText/back | floatingText/body | floatingText/body/*[local-name() = ('div', 'div1', 'div2', 'div3', 'div4', 'div5')]" mode="tei2hub" priority="2">
      <xsl:apply-templates select="node()" mode="#current"/>
   </xsl:template>
    
  <xsl:template match="abstract" mode="tei2hub">
    <abstract>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </abstract>
  </xsl:template>

  <xsl:variable name="structural-containers" as="xs:string+" select="('dedication', 'marginal', 'motto', 'part', 'article', 'appendix', 'chapter', 'glossary')"/>
  <xsl:variable name="main-structural-containers" as="xs:string+" select="('part', 'article', 'chapter', 'appendix')"/>

  <!-- document structure -->
  <xsl:template mode="tei2hub" match="  div[not(@type = $structural-containers)]
                                      | *[matches(local-name(), 'div[1-9]')]">
    <section>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </section>
  </xsl:template>
  
  <xsl:template mode="tei2hub" priority="2" match="*[self::div[not(@type = ($structural-containers, 'bibliography'))]/@rend | *[matches(local-name(), 'div[1-9]')]]/@rend">
    <xsl:attribute name="role" select="."/>
  </xsl:template>

  <xsl:template match="div[@type = $main-structural-containers]" mode="tei2hub" priority="3">
    <xsl:element name="{@type}">
      <xsl:apply-templates select="@* except @type, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="div[@type = $main-structural-containers]/@rend" mode="tei2hub" priority="3"/>

  <xsl:key name="tei2hub:corresp-meta" match="/TEI/teiHeader/profileDesc/textClass/keywords | /TEI/teiHeader/profileDesc/abstract" use="@corresp"/>
  
  <xsl:template match="@type" mode="tei2hub" priority="2"/>
  
  <xsl:template match="@corresp" mode="tei2hub" priority="3">
    <xsl:attribute name="{if (count(tokenize(., '\s+')) gt 1) then 'linkends' else 'linkend'}" select="replace(., '#', '')"/>
  </xsl:template>
  
  <xsl:template match="div[@type = $main-structural-containers]/@subtype" mode="tei2hub" priority="3">
    <xsl:attribute name="renderas" select="."/>
  </xsl:template>

  <xsl:template match="div[@type = $main-structural-containers]/opener[every $n in node()[normalize-space()] satisfies $n[self::idno]]/idno" mode="tei2hub">
    <biblioid>
       <xsl:apply-templates select="@*, node()" mode="#current"/>
    </biblioid>
  </xsl:template>

  <xsl:template match="div[@type = $main-structural-containers]/opener[every $n in node()[normalize-space()] satisfies $n[self::idno]]/idno/@type" mode="tei2hub" priority="4">
    <xsl:attribute name="class" select="lower-case(.)"/>
  </xsl:template>

  <xsl:template match="argument" mode="tei2hub">
    <abstract>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </abstract>
  </xsl:template>

  <xsl:template match="p[@rend = 'artpagenums']" mode="tei2hub">
    <artpagenums><xsl:apply-templates select="node()" mode="#current"/></artpagenums>
  </xsl:template>
  
  <xsl:template match="epigraph" mode="tei2hub">
    <epigraph>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </epigraph>
  </xsl:template>

  <xsl:template match="state/label | seg/label" mode="tei2hub" priority="2">
    <xsl:apply-templates select="node()" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="head/label | p/label" mode="tei2hub">
    <phrase role="hub:identifier">
      <xsl:apply-templates select="@* except @rend, node()" mode="#current"/>
    </phrase>
  </xsl:template>

  <xsl:template match="pb" mode="tei2hub">
    <xsl:processing-instruction name="pagebreak"/>
  </xsl:template>
  
  <xsl:template match="dateline" mode="tei2hub">
    <date>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </date>
  </xsl:template>
  
  <!-- lists -->
  
  <xsl:template match="list[@type eq 'gloss']" mode="tei2hub" priority="2">
    <variablelist>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </variablelist>
  </xsl:template>
  
  <xsl:template match="*:variablelist[*:term]" mode="clean-up" priority="2">
    <xsl:copy copy-namespaces="no">
      <xsl:for-each-group select="*" group-starting-with="*:term">
        <xsl:element name="varlistentry">
          <xsl:apply-templates select="current-group()" mode="#current"/>
        </xsl:element>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="list[@type eq 'gloss']/item[preceding-sibling::*[1][self::label]] | item[tei2hub:is-varlistentry(.)]" mode="tei2hub">
    <listitem>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </listitem>
  </xsl:template>
  
  <xsl:template match="list[@type eq 'gloss']/label | label[tei2hub:is-varlistentry(following-sibling::*[1][self::item])] | list[@type eq 'gloss']/item/label" mode="tei2hub">
    <term>
      <xsl:apply-templates select="@* except @rend, node()" mode="#current"/>
    </term>
  </xsl:template>
  
  <xsl:function name="tei2hub:is-varlistentry" as="xs:boolean">
    <xsl:param name="item" as="element(item)?"/>
    <xsl:sequence select="$item/parent::list[@type eq 'gloss'] or $item/@rend = 'varlistentry'"/>
  </xsl:function>
  
  <xsl:template match="item[tei2hub:is-varlistentry(.)]/gloss" mode="tei2hub">
    <para>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </para>
  </xsl:template>
  
  <xsl:template match="list[@type= 'bulleted']" mode="tei2hub" priority="2">
    <itemizedlist>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </itemizedlist>
  </xsl:template>
  
  <xsl:template match="list" mode="tei2hub">
    <orderedlist>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </orderedlist>
  </xsl:template>

  <xsl:template match="list/@type" mode="tei2hub" priority="3"/>
  
  <xsl:template match="list/@style" mode="tei2hub" priority="3">
    <xsl:attribute name="{if (../@type = 'ordered') then 'numeration' else 'mark'}" select="."/>
  </xsl:template>

  <xsl:template match="item/@n" mode="tei2hub" priority="3">
    <xsl:attribute name="override" select="."/>
  </xsl:template>

  <xsl:template match="item" mode="tei2hub">
    <listitem>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </listitem>
  </xsl:template>
  
  <xsl:template match="anchor" mode="tei2hub" priority="2">
    <anchor>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </anchor>
  </xsl:template>

  <xsl:template match="anchor/@n" mode="tei2hub" priority="2">
    <xsl:attribute name="annotations" select="."/>
  </xsl:template>
  
  <xsl:template match="quote" mode="tei2hub">
    <blockquote>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </blockquote>
  </xsl:template>
  
  <xsl:template match="note" mode="tei2hub">
    <footnote>
      <xsl:apply-templates select="@* except @n, @n" mode="#current"/>
      <xsl:if test="not(@n)">
        <xsl:apply-templates select="p[1]/label" mode="#current"/>
      </xsl:if>
      <xsl:apply-templates select="node()" mode="#current"/>
    </footnote>
  </xsl:template>
  
  <xsl:template match="note[@type = 'footnote']/@n" mode="tei2hub">
    <phrase role="hub:identifier"><xsl:value-of select="."/></phrase>
  </xsl:template>

  <xsl:template match="p" mode="tei2hub">
    <para>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </para>
  </xsl:template>
  
  <xsl:template match="lb" mode="tei2hub">
        <br/>
  </xsl:template>
  
  <xsl:template match="figure" mode="tei2hub">
    <figure>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:if test="not(head)"><title/></xsl:if>
      <xsl:apply-templates select="head, bibl[@type = 'copyright'], node()[not(self::head | self::bibl[@type = 'copyright'])] " mode="#current"/>
    </figure>
  </xsl:template>
  
  <xsl:template match="figure/bibl[@type = 'copyright']" mode="tei2hub" priority="2">
    <info>
      <legalnotice>
        <para>
          <xsl:apply-templates select="@* except @type, node()" mode="#current"/>
        </para>
      </legalnotice>
    </info>
  </xsl:template>

  <xsl:template match="figure/note" mode="tei2hub">
    <note>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </note>
  </xsl:template>

  <xsl:template match="figure/p" mode="tei2hub">
    <note>
      <xsl:next-match/>
    </note>
  </xsl:template>
  
  <xsl:template match="graphic/@url" mode="tei2hub">
    <xsl:attribute name="fileref" select="."/>
  </xsl:template>

  <xsl:template match="@indexName" mode="tei2hub">
    <xsl:attribute name="type" select="."/> 
  </xsl:template>
  
  <xsl:template match="index[not(parent::*[self::index])]" mode="tei2hub">
    <indexterm>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </indexterm>
  </xsl:template>

  <xsl:template match="index[parent::*[self::index]]" mode="tei2hub">
      <xsl:apply-templates select="node()" mode="#current"/>
  </xsl:template>

  <xsl:template match="index[not(parent::*[self::index])]/term" mode="tei2hub">
    <primary>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </primary>
  </xsl:template>
  
  <xsl:template match="index[not(parent::*[self::index])]/index/term" mode="tei2hub">
    <secondary>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </secondary>
  </xsl:template>

  <xsl:template match="index[not(parent::*[self::index])]/index/index/term" mode="tei2hub">
    <tertiay>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </tertiay>
  </xsl:template>

  <xsl:template match="see |  address" mode="tei2hub">
    <xsl:element name="{local-name()}" exclude-result-prefixes="#all">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="see-also" mode="tei2hub">
    <seealso>
      <xsl:apply-templates select="node()" mode="#current"/>
    </seealso>
  </xsl:template>

  <xsl:template match="graphic/desc" mode="tei2hub">
    <alt>
      <xsl:apply-templates select="node()" mode="#current"/>
    </alt>
  </xsl:template>

  <xsl:template match="graphic" mode="tei2hub">
    <xsl:element name="{if (parent::*[self::head | self::p | self::hi | self::seg]) then 'inlinemediaobject' else 'mediaobject'}">
      <xsl:apply-templates select="@rend, @srcpath, @css:*, @xml:id" mode="#current"/>
      <imageobject>
        <imagedata><xsl:apply-templates select="@url" mode="#current"/></imagedata>
      </imageobject>
    </xsl:element>
  </xsl:template>

  <xsl:template match="tbody | thead | tfoot | colgroup" mode="tei2hub">
    <xsl:element name="{local-name()}" exclude-result-prefixes="#all">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="td | th" mode="tei2hub">
    <entry>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </entry>
  </xsl:template>

  <xsl:template match="tr" mode="tei2hub">
    <row>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </row>
  </xsl:template>

  <xsl:template match="col" mode="tei2hub">
    <colspec>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </colspec>
  </xsl:template>

  <xsl:template match="lg" mode="tei2hub">
    <div>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </div>
  </xsl:template>
  
  <xsl:template match="l" mode="tei2hub">
    <para>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </para>
  </xsl:template>
  
  <xsl:template match="spGrp" mode="tei2hub">
    <div role="speech"><xsl:apply-templates select="node()" mode="#current"/></div>
  </xsl:template>
  
  <xsl:template match="sp" mode="tei2hub">
      <xsl:apply-templates select="node()" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="stage" mode="tei2hub">
    <para>
    <xsl:apply-templates select="@*, node()" mode="#current"/>
    </para>
  </xsl:template>
  
  <xsl:template match="speaker" mode="tei2hub">
    <para role="speaker">
      <xsl:apply-templates select="@* except @rend, node()" mode="#current"/>>
    </para>
  </xsl:template>
  
  
  <!-- TO DO: label handling-->
  <xsl:template match="head" mode="tei2hub">
    <title>
       <xsl:apply-templates select="@*, node()" mode="#current"/>
    </title>
  </xsl:template>
  
  <xsl:template match="head[@type = 'sub']" mode="tei2hub" priority="2">
    <subtitle>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </subtitle>
  </xsl:template>

  <xsl:template match="head[@type = 'titleabbrev']" mode="tei2hub" priority="2">
    <titleabbrev>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </titleabbrev>
  </xsl:template>
  
  <xsl:template match="caption" mode="tei2hub">
    <caption>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </caption>
  </xsl:template>
  
  <xsl:template match="*:sidebar/*:section | *:div/*:section " mode="clean-up">
      <xsl:apply-templates select="node()" mode="#current"/>
  </xsl:template>

  <xsl:variable name="non-info-elt-names" as="xs:string+" select="('para', 'div', 'sidebar', 'table', 'informaltable', 'bibliography', 'bibliomixed', 'bibliolist', 'bibliodiv', 'figure', 'orderedlist', 'variablelist', 'itemizedlist', 'blockquote', 'section', 'simpara', 'appendix', 'chapter')"/>

  <xsl:template match="*:part[*[not(self::*:info | self::title | self::*:subtitle | self::*:chapter | self::*:appendix)]] " mode="clean-up">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
        <xsl:for-each-group select="node()" group-starting-with="*[local-name() = $non-info-elt-names]
                                                           [preceding-sibling::*[1][self::*:info | self::*:title | self::*:epigraph | self::*:subtitle | self::*:author | self::*:titleabbrev | self::*:abstract[@rend='motto']]] | *:chapter">
        <xsl:choose>
          <xsl:when test="current-group()[1][self::*:info]">
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:when>
          <xsl:when test="current-group()[1][self::*:title | self::*:subtitle]">
            <xsl:element name="info"><xsl:apply-templates select="current-group()" mode="#current"/></xsl:element>
          </xsl:when>
          <xsl:when test="current-group()[1][self::*:chapter]">
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:element name="partintro">
              <xsl:apply-templates select="current-group()" mode="#current"/>
            </xsl:element>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*:section[not(*:info)] | *:chapter[not(*:info)] | *:bibliography[not(*:info)] | *:appendix[not(*:info)] | *:bibliodiv[not(*:info)] | *:bibliolist[not(*:info)] | *:index[not(*:info)]" mode="clean-up">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
       <xsl:for-each-group select="node()" group-starting-with="*[local-name() = $non-info-elt-names]
                                                            [preceding-sibling::*[1][self::*:info | self::*:title | self::*:epigraph | self::*:subtitle | self::*:author | self::*:titleabbrev | self::*:abstract[@rend='motto']]]
                                                           | *:section | *:sect1">
        <xsl:choose>
          <xsl:when test="current-group()[1][self::*:title | self::*:subtitle]">
            <xsl:element name="info"><xsl:apply-templates select="current-group()" mode="#current"/></xsl:element>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*:section[parent::*[self::*:section]] | *:section[*:section]" mode="clean-up" priority="3">
    <xsl:element name="{if ($sections-to-numbered-secs) then concat('sect',count(ancestor-or-self::*:section)) else 'section'}">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="node()" group-starting-with="*[local-name() = $non-info-elt-names]
                                                           [preceding-sibling::*[1][self::*:info | self::*:title | self::*:epigraph | self::*:subtitle | self::*:author | self::*:titleabbrev | self::*:abstract[@rend='motto']]]
                                                           | *:section | *:sect1">
        <xsl:choose>
          <xsl:when test="current-group()[1][self::*:title | self::*:subtitle]">
            <xsl:element name="info"><xsl:apply-templates select="current-group()" mode="#current"/></xsl:element>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>