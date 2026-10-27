"""Convert a simple glTF binary (untextured PBR meshes) to USDZ.

Usage: python3 tools/glb_to_usdz.py in.glb out.usdz
Needs only the stock Python and macOS's /usr/bin/usdcat and usdzip.
"""
import json
import math
import os
import struct
import subprocess
import sys
import tempfile

COMPONENT = {5125: ('I', 4), 5123: ('H', 2), 5121: ('B', 1), 5126: ('f', 4)}
WIDTH = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}


def load(path):
    data = open(path, 'rb').read()
    json_len = struct.unpack('<I', data[12:16])[0]
    doc = json.loads(data[20:20 + json_len])
    bin_start = 20 + json_len + 8
    return doc, data[bin_start:]


def accessor(doc, blob, index):
    acc = doc['accessors'][index]
    view = doc['bufferViews'][acc['bufferView']]
    fmt, size = COMPONENT[acc['componentType']]
    width = WIDTH[acc['type']]
    start = view.get('byteOffset', 0) + acc.get('byteOffset', 0)
    values = struct.unpack_from('<%d%s' % (acc['count'] * width, fmt), blob, start)
    if width == 1:
        return list(values)
    return [values[i:i + width] for i in range(0, len(values), width)]


def smooth_normals(points, indices):
    normals = [[0.0, 0.0, 0.0] for _ in points]
    for i in range(0, len(indices), 3):
        a, b, c = indices[i:i + 3]
        pa, pb, pc = points[a], points[b], points[c]
        u = [pb[k] - pa[k] for k in range(3)]
        v = [pc[k] - pa[k] for k in range(3)]
        n = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]]
        for vertex in (a, b, c):
            for k in range(3):
                normals[vertex][k] += n[k]
    out = []
    for n in normals:
        length = math.sqrt(sum(x * x for x in n)) or 1.0
        out.append(tuple(x / length for x in n))
    return out


def vec(values):
    return ', '.join('(%.6g, %.6g, %.6g)' % tuple(v) for v in values)


def write_usda(doc, blob, path):
    lines = [
        '#usda 1.0',
        '(',
        '    defaultPrim = "Root"',
        '    metersPerUnit = 1',
        '    upAxis = "Y"',
        ')',
        '',
        'def Xform "Root" (',
        '    kind = "component"',
        ')',
        '{',
        '    def Scope "Materials"',
        '    {',
    ]
    for i, material in enumerate(doc['materials']):
        pbr = material.get('pbrMetallicRoughness', {})
        color = pbr.get('baseColorFactor', [1, 1, 1, 1])
        lines += [
            '        def Material "M%d_%s"' % (i, material.get('name', 'mat')),
            '        {',
            '            token outputs:surface.connect = </Root/Materials/M%d_%s/Surface.outputs:surface>' % (i, material.get('name', 'mat')),
            '            def Shader "Surface"',
            '            {',
            '                uniform token info:id = "UsdPreviewSurface"',
            '                color3f inputs:diffuseColor = (%.5f, %.5f, %.5f)' % tuple(color[:3]),
            '                float inputs:metallic = %.4f' % pbr.get('metallicFactor', 1.0),
            '                float inputs:roughness = %.4f' % pbr.get('roughnessFactor', 1.0),
            '                token outputs:surface',
            '            }',
            '        }',
        ]
    lines.append('    }')

    for node in doc['nodes']:
        mesh = doc['meshes'][node['mesh']]
        for p, primitive in enumerate(mesh['primitives']):
            points = accessor(doc, blob, primitive['attributes']['POSITION'])
            indices = accessor(doc, blob, primitive['indices'])
            if 'NORMAL' in primitive['attributes']:
                normals = accessor(doc, blob, primitive['attributes']['NORMAL'])
            else:
                normals = smooth_normals(points, indices)
            material = primitive.get('material', 0)
            name = '%s_%d' % (node.get('name', 'mesh'), p)
            mat_name = 'M%d_%s' % (material, doc['materials'][material].get('name', 'mat'))
            lines += [
                '    def Mesh "%s" (' % name,
                '        prepend apiSchemas = ["MaterialBindingAPI"]',
                '    )',
                '    {',
                '        uniform token subdivisionScheme = "none"',
                '        int[] faceVertexCounts = [%s]' % ', '.join(['3'] * (len(indices) // 3)),
                '        int[] faceVertexIndices = [%s]' % ', '.join(map(str, indices)),
                '        point3f[] points = [%s]' % vec(points),
                '        normal3f[] normals = [%s] (' % vec(normals),
                '            interpolation = "vertex"',
                '        )',
                '        rel material:binding = </Root/Materials/%s>' % mat_name,
                '    }',
            ]
    lines.append('}')
    open(path, 'w').write('\n'.join(lines) + '\n')


def main():
    source, target = sys.argv[1], sys.argv[2]
    doc, blob = load(source)
    with tempfile.TemporaryDirectory() as folder:
        usda = os.path.join(folder, os.path.splitext(os.path.basename(target))[0] + '.usda')
        usdc = usda[:-1] + 'c'
        write_usda(doc, blob, usda)
        subprocess.run(['usdcat', usda, '-o', usdc], check=True)
        if os.path.exists(target):
            os.remove(target)
        subprocess.run(['usdzip', os.path.abspath(target), os.path.basename(usdc)], cwd=folder, check=True)
    print(target, os.path.getsize(target))


if __name__ == '__main__':
    main()
