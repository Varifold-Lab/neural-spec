export const mathMacros = {
  '\\R': '\\mathbb{R}',
  '\\ReLU': '\\operatorname{ReLU}',
  '\\XorSpec': '\\operatorname{XorSpec}',
  '\\RN': '\\operatorname{RN}_{32}',
};

// Math rendering errors must fail the build rather than enter the published page.
export function rejectMathErrors() {
  return (_tree, file) => {
    const error = file.messages.find(message => message.source === 'rehype-katex');
    if (error) file.fail(error.cause?.message || error.reason, error.place);
  };
}
