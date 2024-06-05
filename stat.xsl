<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html" indent="yes" />

    <xsl:template match="/">
        <html>
            <head>
                <title>RTMP Server Stats</title>
                <style>
                    body { font-family: Arial, sans-serif; padding: 50px}
                    table { width: 100%; border-collapse: collapse; }
                    th, td { padding: 8px; border: 1px solid #ddd; }
                    th { background-color: #f2f2f2; }
                    .header { font-size: 24px; margin-bottom: 20px; }
                </style>
            </head>
            <body>
                <div class="header">RTMP Server Stats</div>
                <table>
                    <tr>
                        <th>Live Streams</th>
                        <th>Clients</th>
                        <th>Bandwidth IN</th>
                        <th>Bandwidth OUT</th>
                    </tr>
                    <xsl:for-each select="rtmp/server/application">
                        <tr>
                            <td>
                                <xsl:for-each select="live/stream">
                                    <div><xsl:value-of select="name" /></div>
                                </xsl:for-each>
                            </td>
                            <td>
                                <xsl:value-of select="nclients" />
                                <xsl:text> (</xsl:text>
                                <xsl:value-of select="live/nclients" />
                                <xsl:text> live)</xsl:text>
                            </td>
                            <td>
                                <xsl:for-each select="live/stream">
                                    <div>
                                        <xsl:value-of select="bw_in" />
                                    </div>
                                </xsl:for-each>
                            </td>
                            <td>
                                <xsl:for-each select="live/stream">
                                    <div>
                                        <xsl:value-of select="bw_out" />
                                    </div>
                                </xsl:for-each>
                            </td>
                        </tr>
                    </xsl:for-each>
                </table>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>