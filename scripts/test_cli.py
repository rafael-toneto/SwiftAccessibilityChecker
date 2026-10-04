#!/usr/bin/env python3
"""Acceptance checks against the built CLI. Usage: python3 scripts/test_cli.py <binary>."""
from pathlib import Path
import json
import subprocess
import sys
import tempfile
import unittest
import unicodedata

BINARY = str(Path(sys.argv.pop(1)).resolve()) if len(sys.argv) > 1 else None


def normalized(value):
    # macOS may return equivalent decomposed Unicode paths from filesystem APIs.
    return unicodedata.normalize('NFC', value)


class CommandLineTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='sac reports ')
        self.root = Path(self.temp.name)
        self.source = self.root / 'Tela com espaços.swift'
        self.source.write_text('import SwiftUI\nText("Olá <mundo>").font(.system(size: 12))\n')

    def tearDown(self):
        self.temp.cleanup()

    def run_checker(self, *args):
        return subprocess.run([BINARY, *map(str, args)], text=True, capture_output=True, cwd=self.root)

    def test_bundle_and_machine_stdout(self):
        folder = self.root / 'relatórios'
        run = self.run_checker('--format', 'json', '--report-directory', folder, self.source)
        self.assertEqual(run.returncode, 0, run.stderr)
        stdout = json.loads(run.stdout)
        self.assertEqual(stdout, json.loads((folder / 'report.json').read_text()))
        self.assertEqual(stdout['summary']['byRule'], {'SAC003': 1})
        self.assertIn('sourceContext', stdout['diagnostics'][0])
        self.assertEqual(set(p.name for p in folder.iterdir()),
                         {'report.html', 'report.md', 'report.txt', 'report.json', 'warnings.txt'})
        self.assertIn(normalized(str(folder / 'report.html')), normalized(run.stderr))
        self.assertIn(normalized(f'{self.source}:2:'), normalized((folder / 'warnings.txt').read_text()))
        self.assertIn('&lt;mundo&gt;', (folder / 'report.html').read_text())

    def test_all_formats_and_parent_creation(self):
        for format_name in ('xcode', 'json', 'html', 'markdown', 'text'):
            destination = self.root / 'nested' / format_name
            run = self.run_checker(f'--format={format_name}', '--output', destination, self.source)
            self.assertEqual(run.returncode, 0, run.stderr)
            self.assertEqual(run.stdout, '')
            self.assertIn('SAC003', destination.read_text())

    def test_partial_analysis_records_failure_and_nonzero_exit(self):
        invalid = self.root / 'Unreadable.swift'
        invalid.write_bytes(b'\xff\xfe\xff')
        folder = self.root / 'partial'
        run = self.run_checker('--report-directory', folder, self.source, invalid)
        self.assertEqual(run.returncode, 1, run.stderr)
        report = json.loads((folder / 'report.json').read_text())
        self.assertEqual(list(map(normalized, report['analyzedFiles'])), [normalized(str(self.source))])
        self.assertEqual(report['analysisIssues'][0]['filePath'], str(invalid))
        self.assertEqual(report['analysisIssues'][0]['stage'], 'read')
        self.assertIn('Análise incompleta', (folder / 'report.html').read_text())

    def test_missing_input_still_produces_failure_report(self):
        folder = self.root / 'failed'
        run = self.run_checker('--report-directory', folder, self.root / 'missing.swift')
        self.assertEqual(run.returncode, 66)
        report = json.loads((folder / 'report.json').read_text())
        self.assertEqual(report['analyzedFiles'], [])
        self.assertEqual(len(report['analysisIssues']), 1)
        self.assertIn('Análise incompleta', (folder / 'report.html').read_text())

    def test_empty_directory_and_clean_run_replace_old_warnings(self):
        empty = self.root / 'empty'
        empty.mkdir()
        report = json.loads(self.run_checker('--format', 'json', empty).stdout)
        self.assertEqual(report['analyzedFiles'], [])
        folder = self.root / 'reports'
        self.run_checker('--report-directory', folder, self.source)
        self.source.write_text('Text("Olá").font(.body)\n')
        self.assertEqual(self.run_checker('--report-directory', folder, self.source).returncode, 0)
        self.assertEqual((folder / 'warnings.txt').read_text(), '')
        self.assertEqual(json.loads((folder / 'report.json').read_text())['summary']['totalIssues'], 0)

    def test_usage_errors_and_help(self):
        self.assertEqual(self.run_checker('--help').returncode, 0)
        for args in [[], ['--wat'], ['--format', 'pdf', self.source],
                     ['--output'], ['--output='], ['--report-directory='],
                     ['--report-directory', '--format', 'html', self.source]]:
            self.assertEqual(self.run_checker(*args).returncode, 64, str(args))

    def test_protects_input_and_bundle_files(self):
        original = self.source.read_text()
        self.assertEqual(self.run_checker('--output', self.source, self.source).returncode, 74)
        self.assertEqual(self.source.read_text(), original)
        folder = self.root / 'bundle'
        run = self.run_checker('--report-directory', folder, '--output', folder / 'report.json', self.source)
        self.assertEqual(run.returncode, 64)

    def test_end_of_options_and_duplicate_inputs(self):
        source = self.root / '-View.swift'
        source.write_text(self.source.read_text())
        run = self.run_checker('--format', 'json', '--', '-View.swift', source)
        self.assertEqual(run.returncode, 0, run.stderr)
        report = json.loads(run.stdout)
        self.assertEqual(len(report['analyzedFiles']), 1)
        self.assertEqual(report['summary']['totalIssues'], 1)


if __name__ == '__main__':
    if not BINARY:
        sys.exit(__doc__)
    unittest.main()
