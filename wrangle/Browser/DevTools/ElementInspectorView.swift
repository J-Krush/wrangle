//
//  ElementInspectorView.swift
//  Wrangle
//

import SwiftUI

struct ElementInspectorView: View {
    let session: BrowserSession
    @State private var isSelectMode: Bool = false
    @State private var selectedElement: ElementInfo?
    @State private var breadcrumb: [String] = []
    @State private var computedStyles: [(key: String, value: String)] = []
    @State private var boxModel: BoxModelInfo?
    @State private var attributes: [(key: String, value: String)] = []

    /// JavaScript injected to enable element selection overlay
    private static let inspectorJS = """
    (function() {
        if (window._wrangleInspector) { window._wrangleInspector.enable(); return; }

        var overlay = document.createElement('div');
        overlay.id = '_wrangle_overlay';
        overlay.style.cssText = 'position:fixed;pointer-events:none;z-index:999999;border:2px solid #007AFF;background:rgba(0,122,255,0.1);display:none;';
        document.body.appendChild(overlay);

        var inspector = {
            enabled: false,
            enable: function() {
                this.enabled = true;
                document.addEventListener('mouseover', this.onHover, true);
                document.addEventListener('click', this.onClick, true);
            },
            disable: function() {
                this.enabled = false;
                overlay.style.display = 'none';
                document.removeEventListener('mouseover', this.onHover, true);
                document.removeEventListener('click', this.onClick, true);
            },
            onHover: function(e) {
                if (!inspector.enabled) return;
                var rect = e.target.getBoundingClientRect();
                overlay.style.top = rect.top + 'px';
                overlay.style.left = rect.left + 'px';
                overlay.style.width = rect.width + 'px';
                overlay.style.height = rect.height + 'px';
                overlay.style.display = 'block';
            },
            onClick: function(e) {
                if (!inspector.enabled) return;
                e.preventDefault();
                e.stopPropagation();
                inspector.disable();

                var el = e.target;
                var rect = el.getBoundingClientRect();
                var computed = window.getComputedStyle(el);

                // Build breadcrumb path
                var path = [];
                var node = el;
                while (node && node !== document.body.parentElement) {
                    var tag = node.tagName.toLowerCase();
                    if (node.id) tag += '#' + node.id;
                    else if (node.className && typeof node.className === 'string')
                        tag += '.' + node.className.trim().split(/\\s+/).join('.');
                    path.unshift(tag);
                    node = node.parentElement;
                }

                // Collect attributes
                var attrs = {};
                for (var i = 0; i < el.attributes.length; i++) {
                    attrs[el.attributes[i].name] = el.attributes[i].value;
                }

                // Key computed styles
                var styles = {};
                var keys = ['display','position','width','height','margin','padding',
                    'color','background-color','font-family','font-size','font-weight',
                    'border','border-radius','opacity','overflow','z-index','flex',
                    'grid-template-columns','gap'];
                keys.forEach(function(k) { styles[k] = computed.getPropertyValue(k); });

                // Box model
                var box = {
                    marginTop: parseFloat(computed.marginTop) || 0,
                    marginRight: parseFloat(computed.marginRight) || 0,
                    marginBottom: parseFloat(computed.marginBottom) || 0,
                    marginLeft: parseFloat(computed.marginLeft) || 0,
                    borderTop: parseFloat(computed.borderTopWidth) || 0,
                    borderRight: parseFloat(computed.borderRightWidth) || 0,
                    borderBottom: parseFloat(computed.borderBottomWidth) || 0,
                    borderLeft: parseFloat(computed.borderLeftWidth) || 0,
                    paddingTop: parseFloat(computed.paddingTop) || 0,
                    paddingRight: parseFloat(computed.paddingRight) || 0,
                    paddingBottom: parseFloat(computed.paddingBottom) || 0,
                    paddingLeft: parseFloat(computed.paddingLeft) || 0,
                    width: rect.width,
                    height: rect.height
                };

                window.webkit.messageHandlers.elementInspector.postMessage({
                    tag: el.tagName.toLowerCase(),
                    id: el.id || null,
                    className: (typeof el.className === 'string') ? el.className : '',
                    path: path,
                    attributes: attrs,
                    styles: styles,
                    box: box,
                    text: (el.textContent || '').substring(0, 200)
                });
            }
        };

        window._wrangleInspector = inspector;
        inspector.enable();
    })();
    """

    private static let disableInspectorJS = """
    if (window._wrangleInspector) { window._wrangleInspector.disable(); }
    """

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 6) {
                Button {
                    toggleSelectMode()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "cursorarrow.click.2")
                            .font(.system(size: 11))
                        Text("Select Element")
                            .font(.system(size: 11))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(isSelectMode ? Color.accentColor.opacity(0.2) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                .help("Click an element on the page to inspect it")

                Spacer()

                // Breadcrumb
                if !breadcrumb.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
                            ForEach(Array(breadcrumb.enumerated()), id: \.offset) { _, segment in
                                Text(segment)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                if segment != breadcrumb.last {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 7))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Divider()

            if let element = selectedElement {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // Element summary
                        HStack(spacing: 8) {
                            Text("<\(element.tag)>")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.blue)
                            if !element.id.isEmpty {
                                Text("#\(element.id)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.orange)
                            }
                            if !element.className.isEmpty {
                                Text(".\(element.className.replacingOccurrences(of: " ", with: "."))")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.green)
                            }
                        }

                        // Box Model
                        if let box = boxModel {
                            BoxModelView(box: box)
                        }

                        // Attributes
                        if !attributes.isEmpty {
                            sectionHeader("Attributes")
                            ForEach(Array(attributes.enumerated()), id: \.offset) { _, attr in
                                propertyRow(attr.key, attr.value)
                            }
                        }

                        // Computed Styles
                        if !computedStyles.isEmpty {
                            sectionHeader("Computed Styles")
                            ForEach(Array(computedStyles.enumerated()), id: \.offset) { _, style in
                                propertyRow(style.key, style.value)
                            }
                        }
                    }
                    .padding(8)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "cursorarrow.click.2")
                        .font(.system(size: 24))
                        .foregroundStyle(.tertiary)
                    Text("Select an element to inspect")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(nsColor: Theme.sidebarBackground))
        .onReceive(NotificationCenter.default.publisher(for: .browserElementEvent)) { notification in
            handleElementEvent(notification.userInfo as? [String: Any] ?? [:])
        }
        .onReceive(NotificationCenter.default.publisher(for: .browserRequestElementPick)) { notification in
            let requestedID = notification.userInfo?["sessionID"] as? String
            guard requestedID == nil || requestedID == session.id.uuidString else { return }
            if !isSelectMode {
                toggleSelectMode()
            }
        }
    }

    private func toggleSelectMode() {
        isSelectMode.toggle()
        guard let tab = session.activeTab else { return }
        Task {
            if isSelectMode {
                try? await session.controller?.evaluateJavaScript(Self.inspectorJS, in: tab)
            } else {
                try? await session.controller?.evaluateJavaScript(Self.disableInspectorJS, in: tab)
            }
        }
    }

    private func handleElementEvent(_ body: [String: Any]) {
        isSelectMode = false

        let tag = body["tag"] as? String ?? "unknown"
        let id = body["id"] as? String ?? ""
        let className = body["className"] as? String ?? ""

        selectedElement = ElementInfo(tag: tag, id: id, className: className)
        breadcrumb = body["path"] as? [String] ?? []

        if let attrs = body["attributes"] as? [String: String] {
            attributes = attrs.sorted { $0.key < $1.key }.map { (key: $0.key, value: $0.value) }
        }

        if let styles = body["styles"] as? [String: String] {
            computedStyles = styles.sorted { $0.key < $1.key }
                .filter { !$0.value.isEmpty && $0.value != "none" && $0.value != "normal" && $0.value != "auto" }
                .map { (key: $0.key, value: $0.value) }
        }

        if let box = body["box"] as? [String: Double] {
            boxModel = BoxModelInfo(
                marginTop: box["marginTop"] ?? 0,
                marginRight: box["marginRight"] ?? 0,
                marginBottom: box["marginBottom"] ?? 0,
                marginLeft: box["marginLeft"] ?? 0,
                borderTop: box["borderTop"] ?? 0,
                borderRight: box["borderRight"] ?? 0,
                borderBottom: box["borderBottom"] ?? 0,
                borderLeft: box["borderLeft"] ?? 0,
                paddingTop: box["paddingTop"] ?? 0,
                paddingRight: box["paddingRight"] ?? 0,
                paddingBottom: box["paddingBottom"] ?? 0,
                paddingLeft: box["paddingLeft"] ?? 0,
                width: box["width"] ?? 0,
                height: box["height"] ?? 0
            )
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }

    private func propertyRow(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(key)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .trailing)
            Text(value)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Element Info

private struct ElementInfo {
    let tag: String
    let id: String
    let className: String
}

// MARK: - Box Model

struct BoxModelInfo {
    let marginTop: Double, marginRight: Double, marginBottom: Double, marginLeft: Double
    let borderTop: Double, borderRight: Double, borderBottom: Double, borderLeft: Double
    let paddingTop: Double, paddingRight: Double, paddingBottom: Double, paddingLeft: Double
    let width: Double, height: Double
}

private struct BoxModelView: View {
    let box: BoxModelInfo

    var body: some View {
        VStack(spacing: 0) {
            Text("Box Model")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)

            // Nested box visualization
            ZStack {
                // Margin
                boxLayer(
                    color: .orange.opacity(0.15),
                    top: fmt(box.marginTop), right: fmt(box.marginRight),
                    bottom: fmt(box.marginBottom), left: fmt(box.marginLeft),
                    label: "margin"
                )
                .frame(width: 200, height: 120)

                // Border
                boxLayer(
                    color: .yellow.opacity(0.2),
                    top: fmt(box.borderTop), right: fmt(box.borderRight),
                    bottom: fmt(box.borderBottom), left: fmt(box.borderLeft),
                    label: "border"
                )
                .frame(width: 160, height: 90)

                // Padding
                boxLayer(
                    color: .green.opacity(0.15),
                    top: fmt(box.paddingTop), right: fmt(box.paddingRight),
                    bottom: fmt(box.paddingBottom), left: fmt(box.paddingLeft),
                    label: "padding"
                )
                .frame(width: 120, height: 60)

                // Content
                VStack(spacing: 0) {
                    Text("\(Int(box.width)) x \(Int(box.height))")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.primary)
                }
                .frame(width: 80, height: 30)
                .background(Color.blue.opacity(0.15))
            }
        }
    }

    private func fmt(_ v: Double) -> String {
        v == 0 ? "-" : "\(Int(v))"
    }

    private func boxLayer(color: Color, top: String, right: String, bottom: String, left: String, label: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(color.opacity(0.3), lineWidth: 1)
                )

            VStack {
                Text(top).font(.system(size: 8, design: .monospaced)).foregroundStyle(.secondary)
                Spacer()
                Text(bottom).font(.system(size: 8, design: .monospaced)).foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)

            HStack {
                Text(left).font(.system(size: 8, design: .monospaced)).foregroundStyle(.secondary)
                Spacer()
                Text(right).font(.system(size: 8, design: .monospaced)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 2)
        }
    }
}
